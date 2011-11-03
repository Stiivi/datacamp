# -*- encoding : utf-8 -*-
# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.    
require "rvm/capistrano"
set :rvm_ruby_string, '1.9.2'

set :rails_env, "production"

server "195.210.28.155", :app, :web, :db, :primary => true

# update crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

require "delayed/recipes"
set :rails_env, "production" #added for delayed job
# Delayed Job
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"
