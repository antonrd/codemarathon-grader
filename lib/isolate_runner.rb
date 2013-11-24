#!/usr/bin/env ruby
# Runs a process with some resource limitations
# Spacial status codes:
# 127 - memory limit
# 9 - time limit
require File.dirname(__FILE__) + "/runner_args.rb"

opt = Options.new

box = File.join(File.dirname(__FILE__), "../sandboxes/isolate")
%x{sudo #{box} --time=#{opt.timelimit / 1000.0} --wall-time=#{opt.timelimit / 100.0} --mem=#{opt.mem} -M stat --stdin=#{opt.input} --stdout=#{opt.output} --run -- #{opt.cmd}}
status = File.read("stat").lines.inject({}) { |h, l| k, v = l.strip.split(":"); h[k] = v; h; }

$stderr.puts "Used time: #{status["time"]}"

cmd = "sudo cp /tmp/box/0/box/output ."
puts cmd
system cmd
puts "status: #{$?.exitstatus}"

if status["status"] == "SG"
  File.open(opt.output, "r") do |f|
    f.each_line do |line|
      memory_limit ||= line =~ /Out of memory/
      memory_limit ||= line =~ /Cannot allocate memory/
      memory_limit ||= line =~ /std::bad_alloc/
      break;
    end
  end
end

if memory_limit
  $stderr.puts "Used mem: #{opt.mem}"
else
  $stderr.puts "Used mem: #{status["max-rss"]}" 
end

exit 9 if status["status"] == "TO"
exit 127 if memory_limit

if status.has_key?("exitsig")
  exit_sig = status["exitsig"].to_i
  exit 1
end

if status.has_key?("killed")
  exit 9 if status["killed"].to_i == 1
end

exit 1 if status["status"] == "RE"

exit $?.exitstatus
