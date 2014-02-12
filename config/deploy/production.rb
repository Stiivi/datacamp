set :application, "datanest"
set :repository,  "git://github.com/fairplaysk/datacamp.git"
set :branch, "master"
set :keep_releases, 5

# Code Repository
# =========
set :scm, :git
set :scm_verbose, true
set :deploy_via, :remote_cache

# Remote Server
# =============
set :use_sudo, false
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

# Bundler
# -------
require 'bundler/capistrano'
set :bundle_flags, "--deployment --binstubs"
set :bundle_without, [:test, :development, :deploy, :macosx]

# Rbenv
# -----
default_run_options[:shell] = '/bin/bash --login'

set :user, "deploy"
server "46.231.96.104", :web, :app, :db, :primary => true
set :deploy_to, "/home/apps/#{application}"


# update crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

# Delayed Job
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

namespace :deploy do
  task :start do
    run "sudo sv up datanest"
  end
  task :stop do
    run "sudo sv down datanest"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sudo sv restart datanest"
  end
end
