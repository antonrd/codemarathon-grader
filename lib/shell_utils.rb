# -*- encoding : utf-8 -*-
module ShellUtils
  def verbose_system(cmd)
    puts "==== Running: #{cmd} ===="
    system cmd
    puts "==== Exit status: #{$?.exitstatus} ===="
  end
end
