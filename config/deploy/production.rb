# -*- encoding : utf-8 -*-
set :rails_env, "production"

# update crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"
