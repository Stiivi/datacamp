# -*- encoding : utf-8 -*-
require 'csv'

class CsvImporter
  attr_reader :file, :errors
  attr_accessor :encoding, :batch_id
  
  def initialize(encoding)
    self.encoding = encoding
  end
  
  def load_file path, separator = ",", header_lines = 0
    @file = CsvFile.new(path, separator, header_lines)
    @file.encoding = self.encoding
    if @file.open
      return true
    else
      @errors << I18n.t("assets.preview.file_not_loaded", :path => @path)
      return false
    end
  end
  
  def import_into_dataset(import_file, column_mapping, current_user)
    raise RuntimeException, "Can't import, no file open" unless @file
    
    @import_file = import_file
    @import_file.count_of_imported_lines = 0
    @import_file.status = "in_progress"
    @import_file.save
    
    # Get dataset description
    @dataset_description = @import_file.dataset_description
    @dataset = @dataset_description.dataset
    @dataset_class = @dataset.dataset_record_class
    @field_descriptions = @dataset_description.field_descriptions
    
    # Determine which column is which field
    columns = column_mapping
    
    count = 0
    saved_ids = []
    # Go through each line
    @file.rewind
    while not @file.eof? do
      row = @file.readline
      # FIXME: This should be done entirely without ActiveRecord
      # current speed - about 5000 records / minute
      record = @dataset_class.new
      record.record_status = "new"
      record.batch_id = @batch_id
      record.is_part_of_import = true
      columns.each do |i, field_description_id|
        next unless field_description_id
        field_description = @field_descriptions.find_all{|description|description.id.to_i == field_description_id.to_i}[0]
        next unless field_description
        value = row[i.to_i].to_s
        record[field_description.identifier] = value
      end
      record.save
      count += 1
      saved_ids << record._record_id
      
      self.line_imported(count)
    end
    
    self.file_imported(count)
    
    Change.create(change_type: Change::BATCH_INSERT, user: current_user, change_details: {update_conditions: {_record_id: saved_ids}, update_count: count, batch_file: @import_file.path_file_name})
    
    return count
  end
  
  def line_imported(number)
    @last_line_imported ||= number
    if number - @last_line_imported > 100 # Step for updating @import_file
      @import_file.count_of_imported_lines = number
      @import_file.status = 'in_progress'
      @import_file.save
    end
  end
  
  def file_imported(number)
    @import_file.count_of_imported_lines = number
    @import_file.status = 'success'
    @import_file.save
  end
end
