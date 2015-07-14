# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'datanest'
set :repo_url, "git://github.com/fairplaysk/datacamp.git"

set :rbenv_ruby, File.read('.ruby-version').strip

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/datanest2/deploy"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/newrelic.yml', 'config/datacamp_config.yml', 'config/thinking_sphinx.yml', 'config/production.sphinx.conf', 'config/initializers/secret_token.rb', 'config/initializers/site_keys.rb', 'config/environments/production.rb', 'public/sitemap.xml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'files', 'dumps', 'db/sphinx', 'backup', 'data', 'public/sitemaps')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :ssh_options, {
  forward_agent: true
}

set :passenger_restart_with_touch, true

set :delayed_job_bin_path, 'script'

namespace :deploy do

  desc 'Deploy app for first time'
  task :cold do
    invoke 'deploy:starting'
    invoke 'deploy:started'
    invoke 'deploy:updating'
    invoke 'bundler:install'
    invoke 'deploy:db_setup' # This replaces deploy:migrations
    invoke 'deploy:compile_assets'
    invoke 'deploy:normalize_assets'
    invoke 'deploy:publishing'
    invoke 'deploy:published'
    invoke 'deploy:finishing'
    invoke 'deploy:finished'
  end

  desc 'Setup database'
  task :db_setup do
    on roles(:db) do
      within release_path do
        with rails_env: (fetch(:rails_env) || fetch(:stage)) do
          execute :rake, 'db:create:all'
          execute :rake, 'db:schema:load'
          execute :rake, 'db_staging:schema:load'
          execute :rake, 'db_data:schema:load'

          execute :rake, 'db:migrate'
          execute :rake, 'db_staging:migrate'
          execute :rake, 'db_data:migrate'
        end
      end
    end
  end

  task :refresh_indexes do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          run "rake index:index"
        end
      end
    end
  end

  task :start_search_server do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          run "rake index:update_config"
          run "rake index:server"
        end
      end
    end
  end

  task :dump_db do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          run "rake db:dump"
        end
      end
    end
  end
end
