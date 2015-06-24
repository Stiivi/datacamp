namespace :db do
  task :upgrade_datasets => :environment do
    DatasetDescription.all.each do |description|
      next unless description.dataset.table_exists?
      unless description.dataset.has_column? :batch_record_code
        puts "=> batch_record_code not found in table #{description.identifier}"
        description.dataset.add_column(:batch_record_code, :string)
        puts "=> successfully created batch_record_code column in #{description.identifier}"
      end
    end
  end

  task upgrade_decimal_dataset_descriptions: :environment do
    manager = DatastoreManager.manager_with_default_connection
    decimal_field_descriptions = FieldDescription.all.keep_if{|fd| fd.data_type == :decimal }
    decimal_field_descriptions.each {|dfd| manager.set_dataset_field_type(dfd.dataset_description.identifier, dfd.identifier, dfd.data_type) }
  end
end

