namespace :check do
  desc "Make sure local git is in sync with remote."
  task :revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/#{branch}`
      puts "WARNING: HEAD is not the same as origin/#{branch}"
      puts "Run `git push` to sync changes."
      exit
    end
  end
  before "deploy", "check:revision"
  before "deploy:migrations", "check:revision"
  before "deploy:cold", "check:revision"

  desc "Make sure branch to deploy from is master, in production."
  task :branch_name, roles: :production do
    if branch != 'master'
      puts 'Deploying to production and branch is not master. Stopping...'
      exit
    end
  end
  #before "deploy", "check:branch_name"
  #before "deploy:migrations", "check:branch_name"
  #before "deploy:cold", "check:branch_name"
end
