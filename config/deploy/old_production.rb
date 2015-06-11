# -*- encoding : utf-8 -*-
require 'bundler/capistrano'
set :bundle_without, [:development, :test, :macosx]

set :stages, %w(staging production old_production old_staging)
require 'capistrano/ext/multistage'
set :application, "datanest_capistrano"

set(:deploy_to) { "/var/www/projects/#{application}/#{stage}" }

set :scm, :git
set :repository, "git://github.com/fairplaysk/datacamp.git"
set :use_sudo, false
set :keep_releases, 4
after "deploy", "deploy:cleanup" # keep only the last 4 releases

set(:user) { Capistrano::CLI.ui.ask "user:" }

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Symlink shared resources on each release"
  task :symlink_shared, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
    run "ln -nfs #{shared_path}/config/datacamp_config.yml #{release_path}/config/datacamp_config.yml"
    run "ln -nfs #{shared_path}/config/thinking_sphinx.yml #{release_path}/config/thinking_sphinx.yml"
    run "ln -nfs #{shared_path}/config/production.sphinx.conf #{release_path}/config/production.sphinx.conf"
    run "ln -nfs #{shared_path}/config/initializers/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
    run "ln -nfs #{shared_path}/config/initializers/site_keys.rb #{release_path}/config/initializers/site_keys.rb"
    run "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run "ln -nfs #{shared_path}/files #{release_path}/files"
    run "ln -nfs #{shared_path}/dumps #{release_path}/dumps"
    run "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
    run "ln -nfs #{shared_path}/backup #{release_path}/backup"
    run "ln -nfs #{shared_path}/data #{release_path}/data"
  end

  task :refresh_indexes, :roles => :app do
    run "cd #{release_path}; rake index:index RAILS_ENV=production"
  end

  task :start_search_server, :roles => :app do
    run "cd #{release_path}; rake index:update_config RAILS_ENV=production"
    run "cd #{release_path}; rake index:server RAILS_ENV=production"
  end

  task :dump_db, :roles => :app do
    run "cd #{release_path}; rake db:dump RAILS_ENV=production"
  end
end

#after 'deploy:update_code', 'deploy:symlink_shared'
after "deploy:finalize_update", "deploy:symlink_shared"
# after 'deploy:symlink_shared', 'deploy:dump_db'
# after 'deploy:dump_db', 'deploy:start_search_server'
# after 'deploy:start_search_server', 'deploy:refresh_indexes'

set :default_environment, { 'PATH' => "/usr/local/bin:/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH" }

set :application, "datanest"
set(:deploy_to) { "/home/datanest/rails/#{application}/production" }
server "46.231.96.101", :app, :web, :db, :primary => true

# update crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

require "delayed/recipes"
set :rails_env, "production" #added for delayed job
# Delayed Job
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"
