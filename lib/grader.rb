require 'grader_config'

class Grader

  def initialize
    load_config

    @running = false
  end

  def run
    @running = true
    register_signals

    puts "Ready to grade"

    while running do
      sleep 1 unless process_one_run
    end
  end

  protected

  attr_reader :config, :running

  def register_signals
    ["INT", "TERM"].each do |signal|
      Signal.trap(signal) do
        puts "Stopping..."
        @running = false
      end
    end
  end

  def load_config
    @config = GraderConfig.new("config/grader.yml")
    exit 1 if !config.load
  end

  def process_one_run
    run = Run.pending.earliest_first.first

    return false unless run.present?

    if run.task.nil?
      run.update_attributes(status: Run::STATUS_ERROR,
        message: "Run with an invalid task requested. Skipped.")
    else
      case run.code
      when Run::CODE_UPDATE_TASK
        UpdateTask.new(run, config).call
      when Run::CODE_RUN_TASK
        GradeTask.new(run, config).call
      when Run::CODE_UPDATE_CHECKER
        UpdateChecker.new(run, config).call
      else
        puts "Run #{run.id} has unknown code #{run.code}"
        run.update_attributes(status: Run::STATUS_ERROR,
          message: "Unknown run code. Skipped.")
      end
    end

    true
  end
end
