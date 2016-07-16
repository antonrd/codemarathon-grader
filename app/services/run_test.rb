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
    run_status = 'n/a'
    log_block("RUN TEST") do
      container_id = run_within_docker
      run_status = get_run_status(container_id)
    end

    run_status
  end

  def run_within_docker
    executable = config.value("exec_#{ config_lang }")

    memory_limit_bytes = [[run.max_memory_kb, config.value("min_memory_limit_kb")].max, config.value("max_memory_limit_kb")].min * 1024
    time_limit_seconds = [run.max_time_ms, config.value("max_exec_time_ms")].min / 1000.0
    max_processes = config.value("max_processes")

    puts "======== Execution limits ========"
    puts "Memory limit (bytes): #{ memory_limit_bytes }"
    puts "Memory limit altered by hard grader limits" if memory_limit_bytes != run.max_memory_kb * 1024
    puts "Time limit (seconds): #{ time_limit_seconds }"
    puts "Time limit altered by hard grader limits" if time_limit_seconds != run.max_time_ms / 1000.0
    puts "Maximum processes allowed: #{ max_processes }"
    puts "======== Execution limits ========"

    command = %Q{docker run #{ mappings(input_file) }\
      -m #{ memory_limit_bytes }\
      --cpuset-cpus=0\
      -u #{ docker_container_user } -d --net=none #{ docker_image_name }\
       #{ docker_runner } -i #{ docker_input_file } -o #{ docker_output_file }\
       -p #{ max_processes } -m #{ memory_limit_bytes }\
       -t #{ time_limit_seconds } --\
       \"#{ executable }\"}

    puts command

    container_id = %x{#{ command }}

    if container_id.blank?
      puts "Failed running #{ executable } in a docker container"
    else
      puts "Executed #{ executable } in container #{ container_id }"
    end

    container_id.strip
  end

  def get_run_status container_id
    return Run::TEST_OUTCOME_GRADER_ERROR if container_id.blank?

    run_status = wait_while_finish(container_id)

    puts "Docker logs: #{ docker_logs(container_id) }"
    puts "Container exit status: #{ run_status }"

    run_status = 127 if docker_oomkilled(container_id)

    result = "n/a"

    case run_status
      when 9
        result = Run::TEST_OUTCOME_TIME_LIMIT
      when 127
        result = Run::TEST_OUTCOME_MEMORY_LIMIT
      when 0
        result = check_output(run, local_output_file, answer_file, input_file)
      else
        result = Run::TEST_OUTCOME_RUNTIME_ERROR
    end

    log_block("STATUS") do
      puts result
    end

    result
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

  def docker_container_user
    config.value('docker_container_user')
  end

  def docker_image_name
    config.value('docker_image_name')
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
    correct_output = false
    if run.task.checker
      verbose_system "#{checker_exectutable(run.task)} #{input_file} #{answer_file} #{output_file}"
      correct_output = ($?.exitstatus != 0)
    else
      if config.value(:diff_tool) == "diff"
        checker = "ruby " + Rails.root.join("lib/execs/diff.rb").to_s
        verbose_system "#{checker} #{answer_file} #{output_file}"
        correct_output = ($?.exitstatus != 0)
      else
        correct_output = default_diff_outputs(answer_file, output_file)
      end
    end

    if correct_output
      puts "Output OK"
      Run::TEST_OUTCOME_OK
    else
      puts "Output WA"
      Run::TEST_OUTCOME_WRONG_ANSWER
    end
  end

  def checker_exectutable task
    exec_checker_config_key = "exec_#{ task.checker_lang }_checker"
    ["#{ config.value(exec_checker_config_key) }", task.checker].join(" ")
  end

  def default_diff_outputs answer_file, output_file
    DiffOutputs.new(answer_file, output_file).call
  end
end
