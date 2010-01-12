namespace :db do
  task :upgrade_datasets => :environment do
    DatasetDescription.find(:all).each do |description|
      next unless description.dataset.table_exists?
      unless description.dataset.has_column? :batch_record_code
        puts "=> batch_record_code not found in table #{description.identifier}"
        description.dataset.add_column(:batch_record_code, :string)
        puts "=> successfully created batch_record_code column in #{description.identifier}"
      end
    end
  end
end

