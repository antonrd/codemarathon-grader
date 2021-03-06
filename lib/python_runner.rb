#!/usr/bin/env ruby
# Runs a process with some resource limitations
# Spacial status codes:
# 127 - memory limit
# 9 - time limit
require File.dirname(__FILE__) + "/runner_args.rb"

opt = Options.new

box = File.join(File.dirname(__FILE__), "../sandboxes/python_box.py")
if opt.unittest.nil?
  %x{python #{box} #{opt.python} #{opt.sandbox_user} #{opt.timelimit / 1000.0} #{opt.timelimit / 100.0} #{opt.mem * 1000} #{opt.input} #{opt.cmd} #{opt.output}}
else
  %x{python #{box} #{opt.python} #{opt.sandbox_user} #{opt.timelimit / 1000.0} #{opt.timelimit / 100.0} #{opt.mem * 1000} #{opt.input} #{opt.cmd} #{opt.output} #{opt.unittest}}
end

status = -1000
time_sec = 0
memory_kb = 0
error_msg = ""

begin
  File.open("stat", "r") do |infile|
    line1 = infile.gets
    time_sec = line1.strip.split(":")[1].strip.to_f
    line2 = infile.gets
    memory_kb = line2.strip.split(":")[1].strip.to_i
    line3 = infile.gets
    status = line3.strip.split(":")[1].strip.to_i
    error_msg = ""
    while (line = infile.gets)
      error_msg += line
    end
  end
rescue => err
  puts "Exception: #{err}"
  err
end

$stderr.puts "Used time: #{time_sec}"
$stderr.puts "Used mem: #{memory_kb}"

if status != 0
  $stderr.puts error_msg
  exit 9 if time_sec >= opt.timelimit / 1000.0 || status == 137
  exit 127 if memory_kb >= opt.mem
  exit 127 if !/MemoryError/.match(error_msg).nil?
  exit 127 if !/Cannot allocate memory/.match(error_msg).nil?
  exit 127 if status == -9 || status == -11
  exit 1
end