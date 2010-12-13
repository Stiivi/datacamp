# -*- encoding : utf-8 -*-
set :stages, %w(staging production)
require 'capistrano/ext/multistage'
set :application, "datanest_capistrano"

set(:deploy_to) { "/var/www/projects/#{application}/#{stage}" }

set :scm, :git
set :repository, "git://github.com/fairplaysk/datacamp.git"
set :use_sudo, false

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
    run "ln -nfs #{shared_path}/files #{release_path}/files"
    run "ln -nfs #{shared_path}/index/data #{release_path}/index/data"
  end
  
  task :refresh_indexes, :roles => :app do
    run "cd #{release_path}; rake index:update_config RAILS_ENV=#{rails_env}"
    run "cd #{release_path}; rake index:index RAILS_ENV=#{rails_env}"
  end
  
  task :start_search_server, :roles => :app do
    run "cd #{release_path}; rake index:server RAILS_ENV=#{rails_env}"
  end
  
  task :dump_db, :roles => :app do
    run "cd #{release_path}; rake db:dump RAILS_ENV=#{rails_env}"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'
