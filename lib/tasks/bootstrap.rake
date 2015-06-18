namespace :db do
  task :bootstrap => :environment do
    
    files_to_load = [ "install.rb",
                      "install_user_roles.rb",
                      "install_pages.rb",
                      "install_data_types.rb",
                      "install_system_variables.rb",
                      "install_data_formats.rb",
                      "install_quality_statuses.rb" ]
                      
    total = files_to_load.size; current = 1
    files_to_load.each do |file|
      puts "** (installation process) loading file #{file} (#{current}/#{total}) ..."
      current += 1
      begin
        require File.join(Rails.root, "/install/" + file)
        puts "\e\[32m** (installation process) OK: #{file}\e\[0m"
      rescue Exception => e
        puts "\e\[31m** (installation process) ERROR: #{file} with the following error:"
        puts e
        puts "\e\[0m"
      end
      puts
      puts
    end # each loop
  end
end

