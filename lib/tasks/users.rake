namespace :users do
  
  task :generate_missing_api_keys => :environment do
    User.find(:all).each do |user|
      if user.api_key
        puts "User ##{user.id} has API key. Skipping."
      else
        puts "Generating API key for user ##{user.id}."
        user.generate_api_key unless user.api_key
      end
    end
  end
  
  task :generate_all_api_keys => :environment do
    User.find(:all).each do |user|
      puts "Generating API key for user ##{user.id}."
      user.generate_api_key
    end
  end
  
end