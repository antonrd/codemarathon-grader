require 'grader_logging'
require 'shell_utils'

class GradeTask
  include GraderLogging
  include ShellUtils

  def initialize(run, config)
    @run = run
    @config = config
  end

  def call
    puts "Grade task #{run.task.id} with run #{run.id}"

    execute_run

  rescue KeyError => e
    puts "Grader failed to retrieve config value: #{e.message}"
    puts "Error backtrace:\n #{e.backtrace}"

    run.update_attributes(status: Run::STATUS_ERROR, message: "Internal grader error", log: "#{e.message}\n#{e.backtrace}")
  end

  protected

  attr_reader :run, :config

  def execute_run
    run_dir = prepare_run_directory

    Dir.chdir(run_dir) do
      RedirectOutput.new(LOG_FILE).call do

        data = extract_run_data
        return if data.nil?

        puts "Running process..."
        run.update_attributes(status: Run::STATUS_RUNNING,
                              message: "Running")
        if config.supported_language?(data["lang"])
          if CompileCode.new(config, data["source_code"], data["lang"]).call.nil?
            update_run(Run::STATUS_CE, 'Compilation error')
          else
            if run.task.task_type == Task::TASK_TYPE_PYUNIT
              puts "Creating wrapper code for Python unit test ..."
              File.open("wrapper_code.py", "w") do |f|
                f.write(run.task.wrapper_code)
              end
            end

            puts "Running tests..."
            status, message = run_tests(run, data["lang"])
            update_run(status, message)
          end
        else
          update_run(Run::STATUS_ERROR, 'Unknown language')
        end
      end
    end
  end

  def extract_run_data
    data = nil
    begin
      data = ActiveSupport::JSON.decode(run.data)
      puts "Data received for run #{run.id}: #{data}"
    rescue ActiveSupport::JSON.parse_error
      Rails.logger.warn("Attempted to decode invalid JSON: #{run.data}")
      update_run(Run::STATUS_ERROR, "Attempted to decode invalid JSON: #{run.data}")
      return nil
    end
    data
  end

  def prepare_run_directory
    run_dir = File.join(config.value(:files_root), "sandbox")
    FileUtils.mkdir_p(run_dir)
    FileUtils.rm(Dir.glob(File.join(run_dir, '*')))
    run_dir
  end

  def run_tests(run, language)
    input_file_pat = File.join(config.value(:files_root), config.value(:sync_to), run.task_id.to_s, config.value(:input_file_pattern))
    input_files = Dir.glob(input_file_pat).sort
    output_file_pat = File.join(config.value(:files_root), config.value(:sync_to), run.task_id.to_s, config.value(:output_file_pattern))
    output_files = Dir.glob(output_file_pat).sort

    if input_files.empty? || output_files.empty?
      return [Run::STATUS_ERROR, "No tests"]
    end

    if input_files.count != output_files.count
      return [Run::STATUS_ERROR, "Not matching input/output files (#{input_files.count} vs #{output_files.count}"]
    end

    # for each test, run the program
    test_outcomes = []
    input_files.zip(output_files).map do |input_file, answer_file|
      test_outcome = RunTest.new(config, run, input_file, answer_file, language).call
      return [Run::STATUS_GRADER_ERROR, "The grader seems to be out of order"] if test_outcome == Run::TEST_OUTCOME_GRADER_ERROR
      test_outcomes << test_outcome
    end

    [Run::STATUS_SUCCESS, test_outcomes.join(" ")]
  end
end
