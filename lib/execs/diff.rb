# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

# IO.popen("diff --strip-trailing-cr #{ARGV.join(" ")}") do |diff|
arg_list = ARGV.join(" ")
IO.popen("diff --strip-trailing-cr " + arg_list) do |diff|
  if output = diff.read(512)
    puts output
  end
end

exit $?.exitstatus
