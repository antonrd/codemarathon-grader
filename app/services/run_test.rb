require 'shell_utils'

require 'fileutils'

class RunTest
  include ShellUtils

  DOCKER_START_TIMEOUT = 5.seconds

  def initialize(config, run, input_file, answer_file, config_lang)
    @config = config
    @run = run
    @input_file = input_file
    @answer_file = answer_file
    @config_lang = config_lang
  end

  def call
    run_one_test
  end

  protected

  attr_reader :config, :run, :input_file, :answer_file, :config_lang

  def run_one_test
    # clean_sandbox

    base_name = Pathname.new(input_file).basename
    # puts "Here we are"
    # return "re" if @config["init_#{config_lang}".to_sym].nil?
    # puts "Past the config check"

    # verbose_system(@config["init_#{config_lang}".to_sym] % [input_file])
    # verbose_system(@config["run_#{config_lang}".to_sym] % [base_name])

    # runner = Pathname.new(File.join(File.dirname(__FILE__), @config["runner_#{config_lang}"])).realpath.to_s

    run_status = -1

    if run.task.task_type == Task::TASK_TYPE_PYUNIT
        verbose_system "#{ runner } --time #{ run.max_time_ms } "\
                       "--mem #{ run.max_memory_kb } --procs 1 "\
                       "--python #{ @config[:python_exec] } "\
                       "--sandbox-user #{ @config[:python_sandbox_user] } "\
                       "-i #{ base_name } -o output "\
                       "-- ./wrapper_code.py ./program.py"

        run_status = $?.exitstatus
    else
      # if config_lang == 'python'
        # verbose_system "#{runner} --time #{run.max_time_ms} "\
        #                "--mem #{run.max_memory_kb} --procs 1 "\
        #                "-i #{base_name} -o output "\
        #                "-- ./program.py"

      executable = config.value("exec_#{ config_lang }")

      command = %Q{docker run #{ mappings(input_file) }\
        -m #{ [run.max_memory_kb * 1024, 4 * 1024 * 1024].max }\
        --cpuset-cpus=0\
        -u grader -d --net=none grader2\
         #{ docker_runner } -i #{ docker_input_file } -o #{ docker_output_file }\
         -p 50 -m #{ run.max_memory_kb * 1024 }\
         -t #{ run.max_time_ms } --\
         \"#{ executable }\"}

      puts command
      container_id = %x{#{ command }}
      puts "Running #{ executable } in container #{ container_id }"

      run_status = wait_while_finish(container_id)

      puts "Docker logs: #{ docker_logs(container_id) }"
      puts "Container exit status: #{ run_status }"

      run_status = 127 if docker_oomkilled(container_id)

      # verbose_system "cp #{ local_output_file } ./output"
        # verbose_system "#{runner} --time #{run.max_time_ms} "\
        #                "--mem #{run.max_memory_kb} --procs 1 "\
        #                "--python #{@config[:python_exec]} "\
        #                "--sandbox-user #{@config[:python_sandbox_user]} "\
        #                "-i #{base_name} -o output "\
        #                "-- ./program.py"
      # else
      #   verbose_system "#{runner} --time #{run.max_time_ms} "\
      #                  "--mem #{run.max_memory_kb} --procs 1 "\
      #                  "-i #{base_name} -o output -- ./program"
      # end
    end
    result = "n/a"

    case run_status
      when 9
        result = "tl"
      when 127
        result = "ml"
      when 0
        result = check_output(run, local_output_file, answer_file, input_file)
      else
        result = "re"
    end

    return result
  end

  def mappings(input_file)
    {
      local_sandbox_mapping => docker_sandbox,
      "#{Rails.root}/lib/runner_args.rb" => docker_runner_args,
      "#{Rails.root}/lib/runner_fork.rb" => docker_runner_fork,
      input_file => docker_input_file
    }.map do |from, to|
      "-v #{from}:#{to}"
    end.join(" ")
  end

  def wait_while_finish(container_id)
    time_start = Time.now
    while ((docker_exitcode(container_id) == -1 && (Time.now - time_start) < DOCKER_START_TIMEOUT) || docker_running_state(container_id) == "true") do
      sleep(1)
    end

    docker_exitcode(container_id)
  end

  def docker_running_state(container_id)
    `docker inspect -f '{{.State.Running}}' #{container_id}`.strip
  end

  def docker_exitcode(container_id)
    `docker inspect -f '{{.State.ExitCode}}' #{container_id}`.to_i
  end

  def docker_oomkilled(container_id)
    `docker inspect -f '{{.State.OOMKilled}}' #{container_id}`.strip == "true"
  end

  def docker_logs(container_id)
    `docker logs #{container_id}`.strip
  end

  def docker_cleanup
    `docker rm $(docker ps -aq)`
  end

  def docker_sandbox
    config.value(:sandbox_dir)
  end

  def docker_runner
    File.join(config.value(:sandbox_dir), config.value("runner_#{config_lang}"))
  end

  def docker_input_file
    File.join(config.value(:sandbox_dir), "input")
  end

  def docker_output_file
    File.join(config.value(:sandbox_dir), "output")
  end

  def docker_runner_args
    File.join(config.value(:sandbox_dir), "runner_args.rb")
  end

  def docker_runner_fork
    File.join(config.value(:sandbox_dir), "runner_fork.rb")
  end

  def local_sandbox_mapping
    File.join(config.value(:files_root), "sandbox")
  end

  def local_output_file
    File.join(local_sandbox_mapping, "output")
  end

  def check_output(run, output_file, answer_file, input_file)
    puts "Checking output..."
    if run.task.checker
      # file_extension = config.value("extension_#{run.task.checker}")
      # checker = File.join(config[:files_root], config[:sync_to], run.task_id.to_s, "checker.#{file_extension}")
      verbose_system "#{run.task.checker} #{input_file} #{answer_file} #{output_file}"
    else
      checker = "ruby " + Rails.root.join("lib/execs/diff.rb").to_s
      verbose_system "#{checker} #{answer_file} #{output_file}"
    end

    if $?.exitstatus != 0
      "wa"
    else
      "ok"
    end
  end
end
