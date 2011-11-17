# -*- encoding : utf-8 -*-
class ImportFile < ActiveRecord::Base
  has_attached_file :path, :url => '/../files/:id_:filename'
  
  belongs_to :dataset_description
  
  ###############################################################
  ## Validations
  validates_presence_of :dataset_description_id, :col_separator, :path
  validates_attachment_presence :path
  
  ###############################################################
  ## Getters & Setters
  
  def status
    self[:status] || "ready"
  end
  
  ###############################################################
  ## Loads associated file as instance of CsvFile class
  def file_path
    File.join(Rails.root, 'files', "#{id}_#{path_file_name}")
  end
  
  def default_import_format
    dataset_description.default_import_format if dataset_description
  end
  
  def import_into_dataset(column, current_user)
    importer = CsvImporter.new(encoding)
    importer.batch_id = id
    raise RuntimeException, "can't load file" unless importer.load_file(file_path, col_separator || ",", number_of_header_lines)
    importer.import_into_dataset(self, column, current_user)
  end
end
