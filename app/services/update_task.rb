require 'shell_utils'

class UpdateTask
  include ShellUtils

  LOG_FILE = "grader.log"

  def initialize(run, config)
    @run = run
    @config = config
    @sync_status = true
  end

  def call
    puts 'Update task run: %d' % run.id
    RedirectOutput.new(LOG_FILE).call do
      copy_task_files
    end
    update_run(LOG_FILE)

  rescue KeyError => e
    puts "Grader failed to retrieve config value: #{e.message}"
    puts "Error backtrace:\n #{e.backtrace}"

    run.update_attributes(status: Run::STATUS_ERROR, message: "Internal grader error", log: "#{e.message}\n#{e.backtrace}")
  end

  protected

  attr_reader :run, :config, :sync_status

  def prepare_destination_directory
    to = File.join(config.value(:files_root), config.value(:sync_to), run.task_id.to_s)
    puts "Removing %s" % File.join(to, '*')

    FileUtils.mkdir_p(to)
    FileUtils.rm(Dir.glob(File.join(to, '*')))
    to
  end

  def copy_task_files
    to = prepare_destination_directory

    file_patterns.each do |file_pattern|
      # TODO: handle null values
      from = File.join(run.user.file_path, run.data.to_s, file_pattern)
      puts "Syncing tests from #{from} to #{to}"
      sync_command = "#{config.value(:sync)} #{from} #{to}"

      @sync_status = false if !verbose_system sync_command
      break if !sync_status
    end
  end

  def file_patterns
    [config.value(:input_file_pattern), config.value(:output_file_pattern)]
  end

  def update_run(log_filename)
    if sync_status
      run.update_attributes(status: Run::STATUS_SUCCESS,
                            message: "Done",
                            log: File.read(log_filename))
    else
      run.update_attributes(status: Run::STATUS_ERROR,
                            message: $?,
                            log: File.read(log_filename))
    end
  end
end
