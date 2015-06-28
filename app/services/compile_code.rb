require 'shell_utils'

class CompileCode
  include ShellUtils

  def initialize(config, source_code, language, file_basename=nil)
    @config = config
    @source_code = source_code
    @language = language
    @file_basename = file_basename || config.value(:file_basename)
  end

  def call
    File.open(full_source_name, "w") do |f|
      f.write(source_code)
    end

    if config.compiled_language?(language)
      puts "Compiling #{language} ..."
      config_key = "compile_#{language}"
      compile_command = @config.value(config_key) % [full_source_name, file_basename]
      verbose_system compile_command
    else
      puts "Writing source code to #{full_source_name} ..."
      File.open(full_source_name, "w") do |f|
        f.write(source_code)
        f.chmod(0744)
      end
      return File.absolute_path(full_source_name)
    end

    if $?.nil?
      nil
    else
      $?.exitstatus == 0 ? File.absolute_path(file_basename) : nil
    end
  end

  protected

  attr_reader :config, :source_code, :language, :file_basename

  def full_source_name
    config_key = "extension_#{language}"
    "#{file_basename}.#{config.value(config_key)}"
  end
end
