from codejail import jail_code

import logging
import resource
import sys

# Arg 1 - Python path
# Arg 2 - User running the sandbox
# Arg 3 - Max CPU time
# Arg 4 - Max real time
# Arg 5 - Max memory
# Arg 6 - Stdin file
# Arg 7 - Source code file
# Arg 8 - Output file

logging.basicConfig()

if len(sys.argv) < 9 or len(sys.argv) > 10:
  print >> sys.stderr, "Usage: <python path> <user for sandbox> " \
                      "<max cpu time> <max real time> <max memory> " \
                      "<stdin file> <source file> <output file> " \
                      "[<unit test code]"
  print >> sys.stderr, sys.argv
  sys.exit(1)

python_path = sys.argv[1]
print "Python path: %s" % python_path
sandbox_user = sys.argv[2]
print "Sandbox user: %s" % sandbox_user
max_cpu = float(sys.argv[3])
print "Max CPU: %d" % max_cpu
max_real_time = float(sys.argv[4])
print "Max real time: %d" % max_real_time
max_memory = float(sys.argv[5])
print "Max memory: %d" % max_memory
source_code = ''
with open(sys.argv[7], "r") as f:
  source_code = f.read()
print "Source code len: %d" % len(source_code)
stdin_contents = ''
with open(sys.argv[6], "r") as f:
  stdin_contents = f.read()
output_file = sys.argv[8]
print "Output file: %s" % output_file
unit_test_code = None
if len(sys.argv) >= 10:
  with open(sys.argv[9], "r") as f:
    unit_test_code = f.read()
  print "Unit test code len: %d" % len(unit_test_code)

jail_code.configure('python', python_path, sandbox_user)
jail_code.set_limit('CPU', max_cpu)
jail_code.set_limit('VMEM', max_memory)
jail_code.set_limit('REALTIME', max_real_time)
result = jail_code.jail_code('python', source_code, \
  None, None, stdin_contents, "codemarathon", unit_test_code)

cpu_time = result.res_data.ru_utime + result.res_data.ru_stime
memory_usage = result.res_data.ru_maxrss * resource.getpagesize() / 1024
status = result.status
error_message = result.stderr

with open(output_file, "w") as f:
  f.write(result.stdout)

with open("stat", "w") as f:
  f.write("Time: %f\n" % cpu_time)
  f.write("Memory: %d\n" % memory_usage)
  f.write("Status: %d\n" % status)
  f.write("==== STDERR contents BEGIN ====\n%s\n==== STDERR contents END ====" % error_message)