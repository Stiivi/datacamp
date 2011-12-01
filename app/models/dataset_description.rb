# -*- encoding : utf-8 -*-
class DatasetDescription < ActiveRecord::Base
  has_many :field_descriptions, :include => :translations
  # accepts_nested_attributes_for :field_descriptions
  has_many :relationship_descriptions
  has_many :comments
  belongs_to :category, :class_name => "DatasetCategory"
  
  has_many :relations, :dependent => :destroy
  accepts_nested_attributes_for :relations, :allow_destroy => true
  
  after_save :log_changes
  before_destroy :log_destroy
   
   
  default_scope includes(:translations)
  
  translates :title, :description
  locale_accessor I18N_LOCALES
  
  include Api::Accessable
  
  def field_descriptions_attributes=(new_attributes)
    new_attributes.each do |field, attributes|
      id = attributes.delete(:id)
      FieldDescription.update_all(attributes, {:id => id})
    end
  end
  
  ###########################################################################
  # Validations
  validates_presence_of :identifier
  validates_presence_of_i18n :title, :locales => [I18n.locale]
  
  ###########################################################################
  # Attribute getters
  
  def title
    title = globalize.fetch(I18n.locale, :title)
    title = translations.first.title if title.blank? && translations.first
    title.blank? ? "N/A" : title
  end
  
  ###########################################################################
  # Data fetchers
  def visible_field_descriptions(type = nil, limit = nil)
    type ||= :listing
    where = "is_visible_in_#{type.to_s}".to_sym
    @field_descriptions_cache = {} unless @field_descriptions_cache
    if @field_descriptions_cache[type]
      # puts "using cache for #{self.identifier} → #{type}"
      result = @field_descriptions_cache[type]
    else
      # puts "using db for #{self.identifier} → #{type}"
      @field_descriptions_cache[type] = field_descriptions.where(where => true).includes(:translations)
      result = @field_descriptions_cache[type]
    end
    if limit
      result = result[0, limit]
    end
    result
  end
  
  def self.disabled_in_quick_search
    where(:can_be_disabled_in_quick_search => true)
  end
  
  def all_field_descriptions
    field_descriptions.includes(:translations)
    field_descriptions.find_all{|fd|fd.exists_in_database?}
    # FIXME this must be very slow. Boolean saying if field_description exists in db should
    # be cached as a column of field_descriptions table.
  end
  
  def writable_field_descriptions
    field_descriptions.where("is_derived = 0 OR is_derived IS NULL")
  end
  
  def import_settings
  end
  
  def import_settings= settings
    settings = settings.scan /(\d+)=(\d+)/

    # Make everything non-importable first
    FieldDescription.update_all({:importable => false, :importable_column => nil}, {:dataset_description_id => self.id})
    
    # Selected columns will be importable now
    settings.each do |field, order|
      FieldDescription.update_all({:importable => true, :importable_column => order.to_i}, {:dataset_description_id => self.id, :id => field.to_i})
    end
  end
  
  def importable_fields
    field_descriptions.where(:importable => true).order("importable_column asc")
  end
  
  def visible_fields_in_relation
    field_descriptions.where(is_visible_in_relation: true)
  end
  
  def self.categories
    group_by(&:category).collect{|k,v|k.to_s.empty? ? I18n.t("global.other") : k.to_s}
  end
  
  def field_with_identifier(identifier)
    field_descriptions.where(:identifier => identifier).first
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
    @record_count ||= dataset.dataset_record_class.count_by_sql "select count(_record_id) from #{dataset.table_name} where record_status = 'published'"
    @record_count
  end
  
  def refresh_relation_keys
    relations.each do |relation|
      relationship_dataset_description = (relation.relation_type == 'has_many' ? relation.relationship_dataset_description : self)
      relation.available_keys = relationship_dataset_description.field_descriptions.map{|fd| [fd.title, fd.id]}
    end
  end
  
  def create_relation_tables
    relations.each do |relation|
      if relation.create_relation_field_table && !relation.frozen?
        if relation.relation_type == 'has_and_belongs_to_many' 
          Dataset::DatasetRecord.connection.create_table("rel_#{relation.dataset_description.identifier}_#{relation.relationship_dataset_description.identifier}", primary_key: '_record_id') do |t|
            t.integer "ds_#{relation.dataset_description.identifier.singularize}_id"
            t.integer "ds_#{relation.relationship_dataset_description.identifier.singularize}_id"
          end unless relation.relation_table_exists?
          relation.update_attribute(:relation_table_identifier, relation.locate_relation_table_name)
        elsif  relation.relation_type == 'has_many' 
          Dataset::DatasetRecord.connection.add_column("ds_#{relation.relationship_dataset_description.identifier}", "ds_#{relation.dataset_description.identifier.singularize}_id", :integer) unless Dataset::DatasetRecord.connection.columns("ds_#{relation.relationship_dataset_description.identifier}").map(&:name).include?("ds_#{relation.dataset_description.identifier.singularize}_id")
        elsif  relation.relation_type == 'belongs_to' 
          Dataset::DatasetRecord.connection.add_column("ds_#{relation.dataset_description.identifier}", "ds_#{relation.relationship_dataset_description.identifier.singularize}_id", :integer) unless Dataset::DatasetRecord.connection.columns("ds_#{relation.dataset_description.identifier}").map(&:name).include?("ds_#{relation.relationship_dataset_description.identifier.singularize}_id")
        end
      end
    end
  end
  
private
  def log_changes
    change_details = []
    changed_attributes.each do |attribute, old_value|
      next if attribute == "updated_at"
      next if old_value == self[attribute]
      change_details << {changed_field: attribute, old_value: old_value, new_value: self[attribute]}
    end
    Change.create(change_type: self.id_changed? ? Change::DATASET_CREATE : Change::DATASET_UPDATE, dataset_description: self, user: @handling_user, change_details: change_details)
  end
  def log_destroy
    Change.create(change_type: Change::DATASET_DESTROY, dataset_description_cache: attributes, user: @handling_user)
  end
end
