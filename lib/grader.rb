require 'grader_config'

class Grader

  def initialize
    load_config
  end

  def run
    running = true
    puts "Ready to grade"

    while running do
      ["INT", "TERM"].each do |signal|
        Signal.trap(signal) do
          puts "Stopping..."
          running = false
        end
      end

      sleep 1 unless process_one_run
    end
  end

  private

  attr_reader :config

  def load_config
    @config = GraderConfig.new("config/grader.yml")
    exit 1 if !config.load
  end

  def process_one_run
    found = true

    if run = Run.pending.earliest_first.first
      if run.task.nil?
        run.update_attributes(status: Run::STATUS_ERROR,
          message: "Run with an invalid task requested. Skipped.")
      else
        case run.code
        when Run::CODE_UPDATE_TASK
          UpdateTask.new(run, @config).call
        when Run::CODE_RUN_TASK
          GradeTask.new(run, @config).call
        when Run::CODE_UPDATE_CHECKER
          UpdateChecker.new(run, @config).call
        else
          found = false
          puts "Run #{run.id} has unknown code #{run.code}"
          run.update_attributes(status: Run::STATUS_ERROR,
            message: "Unknown run code. Skipped.")
        end
      end
    end

    found
  end
end
