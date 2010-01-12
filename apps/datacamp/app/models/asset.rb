class Asset < ActiveRecord::Base
  has_attached_file :path, :url => '/../files/:id_:filename'
  
  belongs_to :dataset_description
  
  ###############################################################
  ## Validations
  validates_presence_of :dataset_description_id, :col_separator
  
  ###############################################################
  ## Loads associated file as instance of CsvFile class
  def file_path
    File.join(RAILS_ROOT, 'files', "#{id}_#{path_file_name}")
  end
end
