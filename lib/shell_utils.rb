# -*- encoding : utf-8 -*-
module ShellUtils
  def verbose_system(cmd)
    puts "==== Running: #{cmd} ===="
    res = system cmd
    puts "==== Exit status: #{$?.exitstatus} ===="
    res
  end
end
