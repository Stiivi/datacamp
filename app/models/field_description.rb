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

  after_create :add_dataset_column
  after_update :update_dataset_column
  after_destroy :remove_dataset_column

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

  def data_type_with_default
    data_type || :string
  end

  ###########################################################################
  # Dataset
  def exists_in_database?
    dataset_column_exists?(identifier)
  end

  def add_dataset_column
    return unless dataset_table_exists?
    return if dataset_column_exists?(identifier)

    dataset_description.dataset_schema_manager.add_column(identifier, data_type_with_default)
  end

  private

  def update_dataset_column
    return unless dataset_table_exists?

    if identifier_changed? && identifier_was && identifier && dataset_column_exists?(identifier_was)
      dataset_description.dataset_schema_manager.rename_column(identifier_was, identifier)
    end
    if data_type_changed? && identifier_was && identifier && dataset_column_exists?(identifier)
      dataset_description.dataset_schema_manager.change_column_type(identifier, data_type)
    end
  end

  def remove_dataset_column
    return unless dataset_table_exists?
    return unless dataset_column_exists?(identifier)

    dataset_description.dataset_schema_manager.remove_column(identifier)
  end

  def dataset_table_exists?
    dataset_description && dataset_description.dataset_schema_manager.table_exists?
  end

  def dataset_column_exists?(column)
    dataset_description && dataset_description.dataset_schema_manager.has_column?(column)
  end
end
