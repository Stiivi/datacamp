namespace :users do
  
  task :generate_missing_api_keys => :environment do
    User.find_each do |user|
      if user.api_key
        puts "User ##{user.id} has API key. Skipping."
      else
        puts "Generating API key for user ##{user.id}."
        user.generate_api_key unless user.api_key
      end
    end
  end
  
  task :generate_all_api_keys => :environment do
    User.find_each do |user|
      puts "Generating API key for user ##{user.id}."
      user.generate_api_key
    end
  end
  
  task :cleanup_sessions => :environment do
    db_config = ActiveRecord::Base.configurations[Rails.env]
    sh "mysqldump -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} #{db_config['database']} sessions | gzip -c > #{File.join(Rails.root, '/backup/sessions_backup/', Time.now.strftime("%d-%m-%Y_%H-%M-%S")) + '.gz'}"
    Session.where('sessions.user_id IS NULL AND sessions.updated_at < ?', 1.week.ago).delete_all
  end
  
end