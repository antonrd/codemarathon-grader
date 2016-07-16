require 'shell_utils'

class CompileCode
  include ShellUtils

  def initialize(config, task, run_data, file_basename=nil)
    @config = config
    @task = task
    @source_code = run_data["source_code"]
    @language = run_data["lang"]
    @wrapper_code = run_data["wrapper_code"]
    @file_basename = file_basename || config.value(:file_basename)
  end

  def call
    log_block("SOURCE CODE") do
      puts source_code
    end

    if task && task.task_type == Task::TASK_TYPE_UNIT
      puts "Creating wrapper code for a unit test ..."
      File.open(solution_source_file, "w") do |f|
        f.write(wrapper_code)
      end

      puts "Creating unit test code with the user solution ..."
      File.open(unit_solution_file, "w") do |f|
        f.write(source_code)
      end
    else
      File.open(solution_source_file, "w") do |f|
        f.write(source_code)
      end
    end

    if config.compiled_language?(language)
      puts "Compiling #{language} ..."
      log_block("COMPILATION") do
        config_key = "compile_#{language}"

        source_file_list = nil
        if task && task.task_type == Task::TASK_TYPE_UNIT
          source_file_list = [solution_source_file, unit_solution_file].join(" ")
        else
          source_file_list = solution_source_file
        end

        compile_command = @config.value(config_key) % [source_file_list, file_basename]
        verbose_system compile_command
      end
    else
      return File.absolute_path(solution_source_file)
    end

    if $?.nil?
      nil
    else
      $?.exitstatus == 0 ? File.absolute_path(file_basename) : nil
    end
  end

  protected

  attr_reader :config, :task, :source_code, :language, :wrapper_code, :file_basename

  def solution_source_file
    "#{ file_basename }.#{ language_extension }"
  end

  def unit_solution_file
    "#{ config.value(:unit_solution) }.#{ language_extension }"
  end

  def language_extension
    config.value("extension_#{ language }")
  end
end
