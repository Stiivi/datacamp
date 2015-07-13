# -*- encoding : utf-8 -*-
class FieldDescription < ActiveRecord::Base

  belongs_to :dataset_description
  belongs_to :data_format
  belongs_to :field_description_category

  translates :title, :description, :category
  locale_accessor I18N_LOCALES

  ###########################################################################
  # Validations
  validates_presence_of :identifier
  validates_uniqueness_of :identifier, :scope => :dataset_description_id
  #validates_presence_of_i18n :category, :title, :locales => [I18n.locale]
  validates_numericality_of :min_width, if: lambda { min_width.present? }

  after_save :update_in_database
  after_create :setup_in_database

  ###########################################################################
  # Default scope
  default_scope order('weight asc')

  ###########################################################################
  # Methods
  def to_s
    category.blank? ? title : "#{title} (#{category})"
  end

  def title
    title = globalize.fetch I18n.locale, :title
    title = translations.first.title if title.blank? && translations.first.present?
    title.blank? ? "n/a" : title
  end

  ###########################################################################
  # Dataset
  def exists_in_database?
    dataset_description.transformer.has_column?(identifier)
  end

  ###########################################################################
  # Private
  private

  def setup_in_database
    return false unless identifier
    return false unless dataset_description.transformer.table_exists?
    return false if dataset_description.transformer.has_column?(identifier.to_s)

    dataset_description.transformer.create_column_for_description(self)
  end

  # Update data type in database
  def update_in_database
    # Again -- no dataset assigned, no data types.
    return unless dataset_description
    return unless data_type
    manager = DatastoreManager.manager_with_default_connection
    current_data_type = manager.dataset_field_type(dataset_description.identifier, self.identifier)
    # Ulozi sa iba ked sa zmenil typ -> priamo sa to nastavi v databaze
    unless data_type.to_s == current_data_type.to_s
      manager.set_dataset_field_type(dataset_description.identifier, self.identifier, data_type)
    end
  end
end
