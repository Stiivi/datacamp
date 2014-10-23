# -*- encoding : utf-8 -*-
require 'site_map_generator'

namespace :sitemap do

  task :generate_all_files do
    SiteMapGenerator.generate_all_files
  end
  
  task :create_site_map do
    SiteMapGenerator.create_site_map
  end

end
