# -*- encoding : utf-8 -*-
# Add RVM's lib directory to the load path.
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.    
require "rvm/capistrano"

require 'bundler/capistrano'

set :rvm_ruby_string, '1.9.2'

set :stages, %w(staging production)
require 'capistrano/ext/multistage'
set :application, "datanest_capistrano"

set(:deploy_to) { "/var/www/projects/#{application}/#{stage}" }

set :scm, :git
set :repository, "git://github.com/fairplaysk/datacamp.git"
set :use_sudo, false
set :branch, 'rails3'
set :keep_releases, 4 

set(:user) { Capistrano::CLI.ui.ask "user:" }
server "195.210.28.155", :app, :web, :db, :primary => true

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  desc "Symlink shared resources on each release"
  task :symlink_shared, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/datacamp_config.yml #{release_path}/config/datacamp_config.yml"
    run "ln -nfs #{shared_path}/config/sphinx.yml #{release_path}/config/sphinx.yml"
    run "ln -nfs #{shared_path}/config/#{rails_env}.sphinx.conf #{release_path}/config/#{rails_env}.sphinx.conf"
    run "ln -nfs #{shared_path}/files #{release_path}/files"
    run "ln -nfs #{shared_path}/dumps #{release_path}/dumps"
    run "ln -nfs #{shared_path}/db/sphinx #{release_path}/db/sphinx"
  end
  
  task :refresh_indexes, :roles => :app do
    run "cd #{release_path}; rake index:index RAILS_ENV=#{rails_env}"
  end
  
  task :start_search_server, :roles => :app do
    run "cd #{release_path}; rake index:update_config RAILS_ENV=#{rails_env}"
    run "cd #{release_path}; rake index:server RAILS_ENV=#{rails_env}"
  end
  
  task :dump_db, :roles => :app do
    run "cd #{release_path}; rake db:dump RAILS_ENV=#{rails_env}"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'
# after 'deploy:symlink_shared', 'deploy:dump_db'
# after 'deploy:dump_db', 'deploy:start_search_server'
# after 'deploy:start_search_server', 'deploy:refresh_indexes'

