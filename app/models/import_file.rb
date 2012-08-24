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
  
  def status
    self[:status] || "ready"
  end
  
  def file_path
    File.join(Rails.root, 'files', "#{id}_#{path_file_name}")
  end

  def import_into_dataset(column_mapping, current_user=nil)
    if status == 'ready'
      self.update_attributes(count_of_imported_lines: 0, status: 'in_progress')

      saved_ids = []
      count = 0

      csv_file.parse_all_lines do |row|
        if row != nil
          record = prepare_record
          column_mapping.each do |index, field_desription_id|
            next unless field_desription_id
            field_description = dataset_description_field_descriptions.select{|fd| fd.id == field_desription_id.to_i}.first
            record[field_description.identifier] = row[index.to_i].to_s if field_description.present?
          end
          if record.save
            count += 1
            saved_ids << record._record_id

            if count - self.count_of_imported_lines > 100
              if self.reload.status != 'canceled'
                self.update_attributes(count_of_imported_lines: count, status: 'in_progress')
              else
                break
              end
            end
          end
        end
      end
      
      self.update_attributes(count_of_imported_lines: count, status: 'success') if !self.new_record? && self.reload.status != 'canceled'

      Change.create(change_type: Change::BATCH_INSERT,
                    user: current_user,
                    change_details: {update_conditions: {_record_id: saved_ids},
                                     update_count: count,
                                     batch_file: self.path_file_name},
                    dataset_description: dataset_description
                   )
    else
      # This should never happen
      self.update_attribute(:status, 'failed')
    end
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
  
private
  def prepare_record
    @model ||= get_model
    @model.new(record_status: 'new', batch_id: id, is_part_of_import: true)
  end
  
  def get_model
    dataset_description.dataset.dataset_record_class
  end
  
  def csv_file
    @csv_file ||= CsvFile.new(file_path, col_separator, encoding, id, skip_first_line?, has_header?)
  end
  
  def init_values
    self.col_separator ||= ','
  end
end
