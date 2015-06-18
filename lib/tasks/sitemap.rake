namespace :sitemap do

  task :generate_all_files => :environment do
    SiteMapGenerator.generate_all_files
  end
  
  task :create_site_map  => :environment do
    SiteMapGenerator.delay.create_site_map
  end

end
