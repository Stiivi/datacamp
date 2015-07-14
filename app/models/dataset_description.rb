# -*- encoding : utf-8 -*-
class DatasetDescription < ActiveRecord::Base
  has_many :similar_datasets,
           source: :dataset_description_source,
           foreign_key: :similar_source_id

  has_many :similar_dataset_descriptions,
           through: :similar_datasets,
           source: :dataset_description_target

  has_many :field_descriptions, :include => :translations
  has_many :field_descriptions_for_search, conditions: { is_visible_in_search: true }, class_name: 'FieldDescription'
  has_many :field_descriptions_for_detail, conditions: { is_visible_in_detail: true }, class_name: 'FieldDescription'
  has_many :derived_field_descriptions, conditions: { is_derived: true }, class_name: 'FieldDescription'


  has_many :category_assignments
  has_many :field_description_categories,
            include: :translations,
            through: :category_assignments

  has_many :comments
  belongs_to :category, :class_name => "DatasetCategory"

  has_many :relations, :dependent => :destroy
  accepts_nested_attributes_for :relations, :allow_destroy => true
  has_many :relationship_dataset_descriptions, through: :relations

  after_save :log_changes
  before_destroy :log_destroy

  scope :active, conditions: { is_active: true }

  default_scope includes(:translations)

  translates :title, :description, :perex
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
      @field_descriptions_cache[type] = field_descriptions.includes(:translations, :data_format).where(where => true)
      @field_descriptions_cache[type].unshift FieldDescription.new(identifier: '_record_id') if type == :export
      result = @field_descriptions_cache[type]
    end
    if limit
      result = result[0, limit]
    end
    result
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

  def dataset_model
    @dataset_model ||= Dataset::ModelBuilder.new(self).build
  end

  def reload_dataset_model
    @dataset_model = nil
    dataset_model
  end

  def dataset_schema_manager
    Dataset::SchemaManager.new(Dataset::Naming.table_name(self))
  end

  def create_dataset_table
    Dataset::TableCreator.new(self, dataset_schema_manager).create
  end

  def has_derived_fields?
    derived_field_descriptions.exists?
  end

  ###########################################################################
  # Other information about dataset description / dataset

  def record_count
    # FIXME: keep this information cached and retrieve it from cache
    @record_count ||= dataset_model.where(record_status: Dataset::RecordStatus.find(:published)).count
  end

  def refresh_relation_keys
    relations.each do |relation|
      relationship_dataset_description = (relation.relation_type == 'has_many' ? relation.relationship_dataset_description : self)
      relation.available_keys = relationship_dataset_description.field_descriptions.map{|fd| [fd.title, fd.id]}
    end
  end

  def fetch_changes
    Dataset::DcUpdate.find_all_by_updatable_type(dataset_model.name)
  end

  def fetch_relations
    Dataset::DcRelation.where('relatable_left_type = ? or relatable_right_type = ?', dataset_model.name, dataset_model.name)
  end

  def each_published_records
    dataset_model.where(record_status: Dataset::RecordStatus.find(:published)).find_each do |record|
      yield record
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
