# -*- encoding : utf-8 -*-

# Bundler
# -------
require 'bundler/capistrano'
set :bundle_flags, "--deployment --binstubs"
set :bundle_without, [:test, :development, :deploy, :macosx]


# multistage
set :stages, %w(staging production old_production old_staging)
require 'capistrano/ext/multistage'
set :application, "datanest"

# Code Repository
# =========
set :scm, :git
set :repository, "git://github.com/fairplaysk/datacamp.git"
set :scm_verbose, true
set :deploy_via, :remote_cache

# Remote Server
# =============
set :use_sudo, false
ssh_options[:forward_agent] = true
default_run_options[:pty] = true

# Rbenv
# -----
default_run_options[:shell] = '/bin/bash --login'

set :keep_releases, 5
after "deploy", "deploy:cleanup" # keep only the last 4 releases

set :user, "deploy"
server "46.231.96.104", :web, :app, :db, :primary => true
set :deploy_to, "/home/apps/#{application}"

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

  desc "Symlink shared resources on each release"
  task :symlink_shared, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
    run "ln -nfs #{shared_path}/config/datacamp_config.yml #{release_path}/config/datacamp_config.yml"
    run "ln -nfs #{shared_path}/config/sphinx.yml #{release_path}/config/sphinx.yml"
    run "ln -nfs #{shared_path}/config/production.sphinx.conf #{release_path}/config/production.sphinx.conf"
    run "ln -nfs #{shared_path}/config/initializers/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
    run "ln -nfs #{shared_path}/config/initializers/site_keys.rb #{release_path}/config/initializers/site_keys.rb"
    run "ln -nfs #{shared_path}/config/environments/production.rb #{release_path}/config/environments/production.rb"
    run "ln -nfs #{shared_path}/files #{release_path}/files"
    run "ln -nfs #{shared_path}/dumps #{release_path}/dumps"
    run "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
    run "ln -nfs #{shared_path}/backup #{release_path}/backup"
    run "ln -nfs #{shared_path}/data #{release_path}/data"
    # sitemap
    run "ln -nfs #{shared_path}/public/sitemap.xml #{release_path}/public/sitemap.xml"
    run "ln -nfs #{shared_path}/public/sitemaps #{release_path}/public/sitemaps"
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

after "deploy:finalize_update", "deploy:symlink_shared"
