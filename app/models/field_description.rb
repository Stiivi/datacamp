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
  
  ###########################################################################
  # Finders
  def self.find(*args)
    self.with_scope(:find => {:order => 'weight asc'}) { super }
  end
  
  ###########################################################################
  # Methods
  def to_s
    category.blank? ? title : "#{title} (#{category})"
  end
  
  def title
    title = globalize.fetch self.class.locale, :title
    title.blank? ? "n/a" : title
  end
  
  def data_type
    manager = DatastoreManager.manager_with_default_connection
    @data_type ||= manager.dataset_field_type(dataset_description.identifier, self.identifier)
    @data_type
    
  end
  
  def data_type=(new_type)
    manager = DatastoreManager.manager_with_default_connection
    manager.set_dataset_field_type(dataset_description.identifier, self.identifier, new_type)
  end
  
  ###########################################################################
  # Dataset
  def exists_in_database?
    dataset_description.dataset.has_column?(identifier)
  end
  
  ###########################################################################
  # Callbacks
  def after_create
    setup_in_database
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
end