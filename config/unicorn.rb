root = "/home/grader/applications/grader"
working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"

listen "/tmp/unicorn.tasks_grader.sock"
worker_processes 2
timeout 30
