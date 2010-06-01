namespace :db do
  task :create_indexes => :environment do
    DatasetDescription.all.each do |dataset_description|
      dataset = dataset_description.dataset.table_name
      dataset_description.field_descriptions.each do |field_description|
        field = field_description.identifier
        query = "create index #{field}_index ON #{dataset}(#{field})"
        puts "#{query} ..."
        begin
          DatasetRecord.connection.execute(query)
          puts "Successfuly created index #{field}_index on #{dataset}(#{field})"
        rescue Exception => e
          puts RuntimeError, "Couldn't create index #{field}_index on #{dataset}(#{field})\n#{e.message}", e.backtrace
        end
      end
    end
  end
end