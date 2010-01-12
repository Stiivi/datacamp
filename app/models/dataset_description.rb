class DatasetDescription < ActiveRecord::Base
  has_many :field_descriptions, :include => :globalize_translations
  accepts_nested_attributes_for :field_descriptions
  has_many :relationship_descriptions
  has_many :comments
  belongs_to :category, :class_name => "DatasetCategory"
  
  translates :title, :description
  locale_accessor I18N_LOCALES
  
  ###########################################################################
  # Validations
  validates_presence_of :identifier
  validates_presence_of_i18n :title, :locales => [I18n.locale]
  
  ###########################################################################
  # Attribute getters
  
  ###########################################################################
  # Data fetchers
  def visible_field_descriptions(where = nil)
    where ||= :listing
    where = "is_visible_in_#{where.to_s}".to_sym
    field_descriptions.find :all, :conditions => {where => true}, :include => :globalize_translations
  end
  
  def all_field_descriptions
    field_descriptions.find :all, :include => :globalize_translations
    field_descriptions.find_all{|fd|fd.exists_in_database?}
    # FIXME this must be very slow. Boolean saying if field_description exists in db should
    # be cached as a column of field_descriptions table.
  end
  
  def writable_field_descriptions
    field_descriptions.find :all, :conditions => "is_derived = 0 OR is_derived IS NULL"
  end
  
  def import_settings
  end
  
  def import_settings= settings
    settings = settings.split '&'
    settings.map! { |s| s.split('=') }
    
    settings = Hash[*settings.flatten]
    
    field_descriptions.each do |at|
      at.importable = false
      at.importable_column = nil
      
      if settings[at.id.to_s]
        at.importable = true
        at.importable_column = settings[at.id.to_s]
      end
      
      at.save!
    end
  end
  
  def importable_fields
    field_descriptions.find :all, :conditions => {:importable => true}, :order => "importable_column asc"
  end
  
  def self.categories
    find(:all).group_by(&:category).collect{|k,v|k.to_s.empty? ? I18n.t("global.other") : k.to_s}
  end
  
  def field_with_identifier(identifier)
    field_descriptions.find :first, :conditions => {:identifier => identifier}
  end
  
  ###########################################################################
  # Method to retrieve the actual dataset
  def is_hidden?
    return ! self.is_active
  end
  
  def dataset
    @dataset ||= Dataset::Base.new(self)
    @dataset
  end
  
  def dataset_record_class
    self.dataset.dataset_record_class
  end
  
  ###########################################################################
  # Other information about dataset description / dataset
  
  def record_count
    # FIXME: keep this information cached and retrieve it from cache
    @record_count ||= dataset.dataset_record_class.count_by_sql "select count(_record_id) from #{dataset.table_name}"
    @record_count
  end
  
end
