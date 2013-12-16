require "bundler/capistrano"

load "config/recipes/base"
# load "config/recipes/rbenv"
load "config/recipes/check"

server "176.58.110.176", :web, :app, :db, :production, primary: true
#server "myedu-test.epfl.ch", :web, :app, :db, :staging, primary: true

set :application, "tasks_grader"
set :user, "deployer"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@bitbucket.org:antonrd/tasks-grader.git"
set :branch, "master"
#set :branch, "develop"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
 %w[start stop restart].each do |command|
   desc "#{command} unicorn server"
   task command, roles: :app, except: {no_release: true} do
     run "/etc/init.d/unicorn_#{application} #{command}"
   end
 end

  # task :restart do
  #   run "touch #{current_path}/tmp/restart.txt"
  # end

  # Define start/stop as no ops, as they are not supported by Passenger
  # %w[:start, :stop].each do |task|
  #   # Do nothing for those tasks.
  # end

  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    run "mkdir -p #{shared_path}/uploads"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.example.yml"), "#{shared_path}/config/database.yml"
    put File.read("config/grader.example.yml"), "#{shared_path}/config/grader.yml"
    puts "Now edit the config files in #{shared_path}."
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/grader.yml #{release_path}/config/grader.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"
  
  desc "Reload the database with seed data"
  task :seed do
    run "cd #{current_path}; bundle exec rake db:seed RAILS_ENV=production"
  end
end