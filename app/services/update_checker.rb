require 'grader_logging'

class UpdateChecker
  include GraderLogging

  def initialize run, config
    @run = run
    @config = config
  end

  def call
    puts "Update checker for task #{run.task.id} with run #{run.id}"

    update_checker

  rescue KeyError => e
    puts "Grader failed to retrieve config value: #{e.message}"
    puts "Error backtrace:\n #{e.backtrace}"

    run.update_attributes(status: Run::STATUS_ERROR, message: "Internal grader error", log: "#{e.message}\n#{e.backtrace}")
  end

  protected

  attr_reader :run, :config

  def update_checker
    # TODO: Change this to be run in the sandbox using docker maybe.
    run_dir = File.join(config.value(:files_root), config.value(:sync_to), run.task_id.to_s)

    Dir.chdir(run_dir) do
      RedirectOutput.new(LOG_FILE).call do
        begin
          data = ActiveSupport::JSON.decode(run.data)
          puts "Data received for run #{run.id}: #{data}"
        rescue ActiveSupport::JSON.parse_error
          Rails.logger.warn "Attempted to decode invalid JSON: #{run.data}"
          update_run(Run::STATUS_ERROR, "Attempted to decode invalid JSON: #{run.data}")
          return
        end

        if data["source_code"].empty?
          run.task.update_attribute(:checker, nil)
          update_run(Run::STATUS_SUCCESS, "Default checker set")
        else
          checker_path = CompileCode.new(config, data["source_code"], data["lang"], "checker").call

          if checker_path.present?
            update_run(Run::STATUS_SUCCESS, "New checker set")
            run.task.update_attribute(:checker, checker_path)
          else
            update_run(Run::STATUS_CE, "Compilation error")
          end
        end
      end
    end
  end
end
