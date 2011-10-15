class Relation < ActiveRecord::Base
  attr_accessor :available_keys
  
  belongs_to :dataset_description
  belongs_to :relationship_dataset_description, :class_name => 'DatasetDescription', :foreign_key => :relationship_dataset_description_id
  belongs_to :foreign_key_field_description, :class_name => 'FieldDescription', :foreign_key => :foreign_key_field_description_id
  
  validates_presence_of :dataset_description, :relation_type, :relationship_dataset_description_id
  validates_uniqueness_of :dataset_description_id, :scope => [:relation_type, :relationship_dataset_description_id]
end
