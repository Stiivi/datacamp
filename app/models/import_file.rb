# -*- encoding : utf-8 -*-
class ImportFile < ActiveRecord::Base
  belongs_to :dataset_description
  has_attached_file :path, :url => '/../files/:id_:filename'
  
  CSV_TEMPLATE                  = { id: "csv",                  title: "CSV" }
  CSV_EXTENDED_HEADER_TEMPLATE  = { id: "csv_extended_header",  title: "CSV with extended header" }
  CSV_NO_HEADER_TEMPLATE        = { id: "csv_no_header",        title: "CSV with no header" }
  CSV_TEMPLATES = [ ImportFile::CSV_TEMPLATE, ImportFile::CSV_EXTENDED_HEADER_TEMPLATE, ImportFile::CSV_NO_HEADER_TEMPLATE ]
  
  validates_presence_of :dataset_description_id, :col_separator, :path
  validates_attachment_presence :path, message: I18n.t('validations.blank')

  after_initialize :init_values

  serialize :unparsable_lines

  def status
    self[:status] || "ready"
  end
  
  def file_path
    File.join(Rails.root, 'files', "#{id}_#{path_file_name}")
  end

  def import_into_dataset(column_mapping, current_user=nil)
    return unless status == 'ready'

    CsvImport::Runner.new(
        csv_file,
        CsvImport::Record.new(
            dataset_description.dataset_model,
            CsvImport::Mapper.new(column_mapping, dataset_description_field_descriptions),
            self
        ),
        CsvImport::Listener.new(self, Change, current_user: current_user),
        CsvImport::Interceptor.new(self)
    ).run
  end

  def default_import_format
    if self.file_template.present?
      self.file_template
    elsif self.dataset_description.present?
      self.dataset_description.default_import_format 
    else
      SystemVariable.get('default_import_format')
    end
  end
  
  def attachment_csv_errors
    errors[:path] << I18n.t('errors.invalid_csv_file') unless csv_file.is_valid?
  end
  
  def header
    csv_file.header
  end
  
  def sample
    csv_file.sample
  end
  
  def mapping_from_header
    header.map do |h| 
      dataset_description_field_descriptions.select{|fd| fd.identifier == h}.first.try(:id)
    end
  end
  
  def dataset_description_field_descriptions
    @dataset_description_field_descriptions ||= dataset_description.field_descriptions
  end
  
  def skip_first_line?
    CSV_EXTENDED_HEADER_TEMPLATE[:id] == self.file_template
  end
  
  def has_header?
    [CSV_EXTENDED_HEADER_TEMPLATE[:id], CSV_TEMPLATE[:id]].include?(self.file_template)
  end

  def cancel
    update_attribute(:status, 'canceled')
  end

  def delete_records!
    dataset_description.dataset_model.where(batch_id: id).delete_all
    update_attribute(:status, 'deleted_records')
  end

  private
  
  def csv_file
    @csv_file ||= CsvFile.new(file_path, col_separator, encoding, skip_first_line?, has_header?)
  end
  
  def init_values
    self.col_separator ||= ','
  end
end
