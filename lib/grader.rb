# -*- encoding : utf-8 -*-
require "shell_utils"
require "sets_sync"

require 'fileutils'

class Grader
  include ShellUtils
  attr_reader :root, :user, :runner, :tests_updated_at, :grader_app
  
  LANG_TO_COMPILER = {}

  class << self
    def with_stdout_and_stderr(new_stdout, new_stderr, &block)
      old_stdout, old_stderr = $stdout.dup, $stderr.dup
      STDOUT.reopen(new_stdout)
      STDERR.reopen(new_stderr)
      
      yield
    ensure
      STDOUT.reopen(old_stdout)
      STDERR.reopen(old_stderr)
    end
  end

  # def initialize(root='', user)
  def initialize
    # @root = root
    # @user = user
    
    # sync_tests(Time.now)
    @config = get_config
  end

  def get_config
    grader_conf = YAML.load_file(Rails.root.join("config/grader.yml"))
    puts "Reading configuration for env #{Rails.env}"
    if !grader_conf[Rails.env]
      puts "Cannot find configuration for #{Rails.env}. Check your config/grader.yml"
      exit 1
    end
    grader_conf[Rails.env].with_indifferent_access
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
      
      # check_durty_tests

      found = false
      if run = Run.pending.earliest_first.first
        case run.code
        when Run::CODE_UPDATE_TASK
          found = true
          process_task_update(run)
        when Run::CODE_RUN_TASK
          found = true
          grade(run)
        when Run::CODE_UPDATE_CHECKER
          found = true
          update_checker(run)
        end
      end

      if !found
        sleep 1
      end
    end
  end

  def update_checker(run)
    Dir.chdir(File.join(@config[:files_root], @config[:sync_to], run.task_id.to_s)) do
      File.open("grader.log", "w") do |f|
        data = ActiveSupport::JSON.decode(run.data)
        if data["source_code"].empty?
          run.task.update_attribute(:checker, nil)
          run.update_attribute(:status, Run::STATUS_SUCCESS)
        else
          if compile(data["source_code"], data["lang"], "checker")
            run.update_attribute(:status, Run::STATUS_SUCCESS)
            run.task.update_attribute(:checker, data["lang"])
          else
            run.update_attributes(status: Run::STATUS_CE,
                                  log: File.read("grader.log"))
          end
        end
      end
    end
  end

  def process_task_update(run)
    puts 'Update task run: %d' % run.id
    from = File.join(run.user.file_path, run.data.to_s, '*')
    to = File.join(@config[:files_root], @config[:sync_to], run.task_id.to_s)
    FileUtils.mkdir_p(to)
    puts "Removing %s" % File.join(to, '*')
    FileUtils.rm(Dir.glob(File.join(to, '*')))
    puts "Syncing tests from #{from} to #{to}"
    sync_command = "%s #{from} #{to}" % @config[:sync]
    if system sync_command
      run.update_attribute(:status, Run::STATUS_SUCCESS)
    else
      run.update_attributes(status: Run::STATUS_ERROR, message: $?)
    end    
  end

  def grade(run)
    puts 'Grade task run: %d' % run.id
    data = ActiveSupport::JSON.decode(run.data)
    puts data
    run_dir = File.join(@config[:files_root], @config[:runs_dir], run.id.to_s)
    FileUtils.mkdir_p(run_dir)
    FileUtils.rm(Dir.glob(File.join(run_dir, '*')))
    Dir.chdir(run_dir) do
      File.open("grader.log", "w") do |f|
        f.sync = true
        puts 'here'
        self.class.with_stdout_and_stderr(f, f) do
          puts "Running process..."
          run.update_attributes(status: Run::STATUS_RUNNING,
                                message: "Running")
          if data["lang"] == 'c++' || data["lang"] == 'java'
            if !compile(data["source_code"], data["lang"])
              run.update_attributes(status: Run::STATUS_CE, 
                message: 'Compilation error', 
                log: File.read("grader.log"))
            else
              input_file_pat = File.join(@config[:files_root], @config[:sync_to], run.task_id.to_s, 'input.*.txt')
              # puts input_file_pat
              input_files = Dir.glob(input_file_pat)
              output_file_pat = File.join(@config[:files_root], @config[:sync_to], run.task_id.to_s, 'solve.*.txt')
              output_files = Dir.glob(output_file_pat)
              # puts input_files
              # puts output_files
              puts "Running tests..."
              status = run_tests(run, input_files, output_files, data["lang"])

              run.update_attributes(status: Run::STATUS_SUCCESS, 
                message: status, 
                log: File.read("grader.log"))
            end
          else
            run.update_attributes(status: Run::STATUS_ERROR, 
              message: 'Unknown language', 
              log: File.read("grader.log"))            
          end
        end
      end
    end
    # Remove the directory after the execution.
    FileUtils.rm_rf(run_dir)
  end
  
  private
    
    def compile(source_code, language, file_name = "program")
      if language == 'c++'
        # puts "Create file " + ("%.cpp" % [file_name])
        File.open("%s.cpp" % [file_name], "w") do |f|
          f.write(source_code)
        end
        
        puts "Compiling C++ ..."
        # verbose_system "g++ program.cpp -o program -O2 -static -lm -x c++"
        verbose_system "g++ %s.cpp -o %s -O2" % [file_name, file_name]
      elsif language == 'java'
        File.open("%s.java" % [file_name], "w") do |f|
          f.write(source_code)
        end
        
        puts "Compiling Java ..."
        # verbose_system "g++ program.cpp -o program -O2 -static -lm -x c++"
        verbose_system "javac %s.java" % [file_name]
      end

      if $?.nil?
        return false
      else
        return $?.exitstatus == 0
      end
    end
    
    def run_tests(run, input_files, output_files, language)
      # for each test, run the program
      input_files.zip(output_files).map { |input_file, answer_file|
        # verbose_system "#{@runner} --user #{@user} --time #{run.problem.time_limit.to_f} --mem #{run.problem.memory_limit} --procs 1 -i #{input_file} -o output -- ./program"
        # verbose_system "./program < #{input_file} > output"
        if language == 'c++'
          verbose_system(@config[:run_cpp] % input_file)
        elsif language == 'java'
          verbose_system(@config[:run_java] % input_file)
        end

        case $?.exitstatus
          when 9
            "tl"
          when 127
            "ml"
          when 0
            check_output(run, answer_file, input_file)
          else
            "re"
        end
      }.join(" ")
    end

    def sync_tests(update_time)
      SetsSync.sync_sets(get_config)
      @tests_updated_at = update_time
      puts "Tests synced for time #{@tests_updated_at} on #{Time.now}"
    end

    def check_durty_tests
      if (last_update = Configuration.get(Configuration::TESTS_UPDATED_AT)) and last_update > @tests_updated_at
        # Download the tests again
        puts "Tests changed at #{last_update}, while the current version is from #{@tests_updated_at}. Syncing..."
        sync_tests(last_update)
      end
    end
    
    def check_output(run, answer_file, input_file)
      if run.task.checker
        checker = File.join(@config[:sync_to], run.task_id.to_s, 'checker')
        verbose_system "#{checker} #{input_file} #{answer_file} output"
      else
        checker = "ruby " + Rails.root.join("lib/execs/diff.rb").to_s
        verbose_system "#{checker} #{answer_file} output"
      end
      
      if $?.exitstatus != 0
        "wa"
      else
        "ok"
      end
      
    end

    def update_attributes(run, dry_run, attrs)
      run.attributes = attrs
      
      run.save unless dry_run
    end
end
