namespace :db_data do
  task :load => :environment do
    Dir[File.join(Rails.root, 'db', 'data', '*.sql')].each do |file|
      File.open(file) do |f|
        f.read.split(';').each do |update|
          Dataset::DatasetRecord.connection.execute(update) if update.present?
        end
      end
    end
  end
end

namespace :db_staging do
  # desc "Raises an error if there are pending migrations"
  task :abort_if_pending_migrations => :environment do
    ActiveRecord::Base.establish_connection Rails.env + "_staging"
    
    if defined? ActiveRecord
      pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate_staging').pending_migrations

      if pending_migrations.any?
        puts "You have #{pending_migrations.size} pending migrations:"
        pending_migrations.each do |pending_migration|
          puts '  %4d %s' % [pending_migration.version, pending_migration.name]
        end
        abort %{Run "rake db_staging:migrate" to update your database then try again.}
      end
    end
  end
  
  desc 'Load the seed data from db/stagingseeds.rb'
  task :seed => [:environment, 'db_staging:abort_if_pending_migrations'] do
    ActiveRecord::Base.establish_connection Rails.env + "_staging"
    
    seed_file = File.join(Rails.root, 'db', 'staging_seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end
  
  desc "Migrate the staging database (options: VERSION=x, VERBOSE=false)."
  task :migrate => :environment do
    ActiveRecord::Base.establish_connection Rails.env + "_staging"
    
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate("db/migrate_staging/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db_staging:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end
  
  
  namespace :schema do
    desc "Create a db/schema_staging.rb file that can be portably used against any DB supported by AR"
    task :dump => :environment do
      require 'active_record/schema_dumper'
      ActiveRecord::Base.establish_connection Rails.env + "_staging"
      
      File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema_staging.rb", "w") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
      Rake::Task["db_staging:schema:dump"].reenable
    end

    desc "Load a schema_staging.rb file into the database"
    task :load => :environment do
      ActiveRecord::Base.establish_connection Rails.env + "_staging"
      
      file = ENV['SCHEMA'] || "#{Rails.root}/db/schema_staging.rb"
      if File.exists?(file)
        load(file)
      else
        abort %{#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/application.rb to limit the frameworks that will be loaded}
      end
    end
  end
end

