# -*- encoding : utf-8 -*-
class FieldDescription < ActiveRecord::Base
  belongs_to :dataset_description
  belongs_to :data_format

  translates :title, :description, :category
  locale_accessor I18N_LOCALES

  ###########################################################################
  # Validations
  validates_presence_of :identifier
  validates_uniqueness_of :identifier, :scope => :dataset_description_id
  validates_presence_of_i18n :category, :title, :locales => [I18n.locale]

  after_save :update_data_type
  after_create :setup_in_database
  after_find :find_data_type

  # Accessors

  attr_accessor :data_type

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
    dataset_description.dataset.has_column?(identifier)
  end

  ###########################################################################
  # Private
  private

  def setup_in_database
    # return false unless dataset_description
    dataset = dataset_description.dataset

    return false unless identifier
    return false unless dataset_description.dataset.table_exists?
    return false if dataset.has_column?(identifier.to_s)

    dataset.create_column_for_description(self)
  end

  def find_data_type
    # If this field is not assigned to a dataset yet,
    # we can't find actual data type in dataset -- thus we
    # can only play with ours.
    return unless dataset_description
    manager = DatastoreManager.manager_with_default_connection
    @data_type = manager.dataset_field_type(dataset_description.identifier, self.identifier)
  end

  def update_data_type
    # Again -- no dataset assigned, no data types.
    return unless dataset_description
    return unless @data_type
    manager = DatastoreManager.manager_with_default_connection
    current_data_type = manager.dataset_field_type(dataset_description.identifier, self.identifier)
    unless @data_type.to_s == current_data_type.to_s
      manager.set_dataset_field_type(dataset_description.identifier, self.identifier, @data_type)

      # FIXME: this restarts the app server for the changes to take effect. It is dependent on how passenger works and should be generalized
      system "touch #{Rails.root.join('tmp', 'restart.txt')}"
    end
  end
end
