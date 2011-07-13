# -*- encoding : utf-8 -*-
require 'csv'

namespace :db do
  task :dump => :environment do
    puts "Loading datasets ..."
    datasets = DatasetDescription.all
    total = datasets.count
    current = 1
    datasets.reverse.each do |dataset_description|
      puts "Dumping #{dataset_description.identifier.ljust(30)}(#{current}/#{total})"
      
      lines = dump_dataset(dataset_description)
      
      puts "Saved #{lines} lines from #{dataset_description.identifier}"
      
      current += 1
    end
  end
end

def dump_dataset(dataset_description)
  dataset = dataset_description.dataset
  dataset_class = dataset.dataset_record_class
  dump_path = Datacamp::Config.get(:dataset_dump_path)
    
  FileUtils.mkdir(dump_path) unless File.exist?(dump_path)
  count = 0
  
  path = File.join(dump_path, "#{dataset_description.identifier}-dump.csv")
  puts "(#{path})"
  File.open(path, "w") do |output|
    fields_for_export = dataset_description.visible_field_descriptions(:export)
    visible_fields = ["_record_id"] + fields_for_export.collect { |field| field.identifier }
     
    output.write(CSV.generate_line(visible_fields))
  
    dataset_class.find_each(:conditions => {:record_status => 'published'}) do |record|
      values = record.values_for_fields(visible_fields)
      line = CSV.generate_line(values.map{|v| v.to_s.force_encoding("utf-8") })
      output.write("#{line}")
      count += 1
    end
  end
  
  count
end