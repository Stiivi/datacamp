require 'csv'

namespace :db do
  task :dump => :environment do
    puts "Loading datasets ..."
    datasets = DatasetDescription.all
    total = datasets.count
    current = 1
    datasets.each do |dataset|
      puts "Dumping #{dataset.identifier.ljust(30)}(#{current}/#{total})"
      
      lines = dump_dataset(dataset)
      puts "Saved #{lines} lines from #{dataset.identifier}"
      
      current += 1
    end
  end
end

def dump_dataset(dataset_description)
  dataset = dataset_description.dataset
  dataset_class = dataset.dataset_record_class
  dump_path = Datacamp::Config.get(:dataset_dump_path)
  connection = DatasetRecord.connection
  
  path = File.join(dump_path, "#{dataset_description.identifier}-dump.csv")
  puts "(#{path})"
  output = File.open(path, "w")
  
  fields_for_export = dataset_description.visible_field_descriptions(:export)
  visible_fields = fields_for_export.collect { |field| field.identifier }
  
  count = 0
  dataset_class.find_each(:batch_size => 100) do |record|
    values = record.values_for_fields(visible_fields)
    line = CSV.generate_line(values)
    output.write("#{line}\n")
    count += 1
 end
 
 count
end