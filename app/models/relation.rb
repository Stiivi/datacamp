class Relation < ActiveRecord::Base
  attr_accessor :available_keys
  attr_accessor :create_relation_field_table
  
  belongs_to :dataset_description
  belongs_to :relationship_dataset_description, :class_name => 'DatasetDescription', :foreign_key => :relationship_dataset_description_id
  
  validates_presence_of :dataset_description, :relationship_dataset_description_id
  validates_uniqueness_of :dataset_description_id, :scope => :relationship_dataset_description_id
end
