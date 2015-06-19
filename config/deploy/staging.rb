set :application, "datanest_staging"
set :deploy_to, "/home/apps/#{application}"

# set :branch, "master"

namespace :deploy do
  task :start do
    run "sudo sv up datanest_staging"
  end
  task :stop do
    run "sudo sv down datanest_staging"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sudo sv restart datanest_staging"
  end
end
