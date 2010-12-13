namespace :index do
  task :update_config => :environment do
    require File.join(Rails.root, "index", "update_config.rb")
  end
  
  task :index do
    system 'mkdir index/data'
    system 'indexer --rotate --all -c index/sphinx.conf'
  end
  
  task :server do
    system 'searchd -c index/sphinx.conf'
  end
  task :server:stop do
    system 'searchd --stop -c index/sphinx.conf'
  end
end