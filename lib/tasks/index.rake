namespace :index do
  task :update_config => :environment do
    require File.join(Rails.root, "index", "update_config.rb")
  end
  
  task :server do
    system 'searchd index/sphinx.conf'
  end
end