set :default_environment, { 'PATH' => "/usr/local/bin:/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH" }

set :application, "datanest"
set(:deploy_to) { "/home/datanest/rails/#{application}/production" }
server "46.231.96.101", :app, :web, :db, :primary => true