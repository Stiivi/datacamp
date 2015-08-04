# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'datanest'
set :repo_url, "git://github.com/fairplaysk/datacamp.git"

set :rbenv_ruby, File.read('.ruby-version').strip

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

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

# set :linked_files, fetch(:linked_files, []).push('public/sitemap.xml', 'config/production.sphinx.conf') # TODO: these do not exist on cold deploy

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'files', 'dumps', 'db/sphinx', 'backup', 'data', 'public/sitemaps')

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

  desc "Ensure Sphinx is running"
  task :ensure_sphinx do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "ts:ensure_running"
        end
      end
    end
  end

  task :refresh_indexes do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "index:index"
        end
      end
    end
  end

  task :start_search_server do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "index:update_config"
          execute :rake, "index:server"
        end
      end
    end
  end

  task :dump_db do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake,  "db:dump"
        end
      end
    end
  end

  task :import_dump do
    dump = ENV['DUMP']
    match = dump.match(/datanest_(.*?)_.*/)
    raise "'#{dump}' does not seem like a datanest dump, expected 'datanest_$DB_*.sql' format" unless match
    database = match[1]

    if File.extname(dump) == ".sql"
      puts "Compressing #{dump} for upload"
      `gzip #{dump}`
      dump = "#{dump}.gz"
    end

    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          upload! dump, "/tmp"
          filename = File.basename(dump)
          execute :gunzip, "/tmp/#{filename}"
          execute :mysql, "-h $DATANEST_MYSQL_HOST -P $DATANEST_MYSQL_PORT -u $DATANEST_MYSQL_USER --password=$DATANEST_MYSQL_PASSWORD datanest_#{database}_#{fetch(:rails_env)} < /tmp/#{File.basename(filename, '.gz')}"
        end
      end
    end
  end
end

after 'deploy:updated', 'deploy:ensure_sphinx'
after "deploy:updated", "newrelic:notice_deployment"
