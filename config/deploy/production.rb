# update crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

require "delayed/recipes"
set :rails_env, "production" #added for delayed job
# Delayed Job
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"
