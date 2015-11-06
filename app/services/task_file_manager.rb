require 'grader_config'

class TaskFileManager
  def initialize(task)
    @task = task
    @config = GraderConfig.new("config/grader.yml")
    @config.load
  end

  def upload_tests(test_cases)
    test_cases.each do |test_case|
      upload_test(test_case)
    end
  end

  def upload_test(test_case)
    task_tests_dir = File.join(config.value(:files_root),
      config.value(:sync_to), task.id.to_s)

    FileUtils.mkdir_p(task_tests_dir)

    destination_path = File.join(task_tests_dir, test_case.original_filename)

    File.open(destination_path, 'wb') do |file|
      file.write(test_case.read)
    end

    # Set the permissions of the copied file to the right ones. This is
    # because the uploads are created with 0600 permissions in the /tmp
    # folder. The 0666 & ~File.umask will set the permissions to the default
    # ones of the current user. See the umask man page for details
    # FileUtils.chmod 0666 & ~File.umask, dest
  end

  def file_list
    destination_path = File.join(config.value(:files_root),
      config.value(:sync_to), task.id.to_s, '*')

    Dir[destination_path].map { |file_path| describe_file(file_path) }.sort { |a, b| a[:file_basename] <=> b[:file_basename] }
  end

  def delete_tests
    Dir[File.join(config.value(:files_root),
      config.value(:sync_to), task.id.to_s, '*')].each do |file_name|
      delete_test_by_full_path(full_path)
    end
  end

  def delete_test file_name
    delete_test_by_full_path(File.join(config.value(:files_root),
      config.value(:sync_to), task.id.to_s, file_name))
  end

  protected

  attr_reader :task, :config

  def describe_file file_path
    puts file_path
    puts File.size(file_path)
    {
      file_basename: File.basename(file_path),
      file_size: File.size(file_path)
    }
  end

  def delete_test_by_full_path full_path
    File.delete(full_path)
  end
end
