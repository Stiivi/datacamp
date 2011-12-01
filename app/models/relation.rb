class Relation < ActiveRecord::Base
  attr_accessor :available_keys
  attr_accessor :create_relation_field_table
  
  belongs_to :dataset_description
  belongs_to :relationship_dataset_description, :class_name => 'DatasetDescription', :foreign_key => :relationship_dataset_description_id
  belongs_to :foreign_key_field_description, :class_name => 'FieldDescription', :foreign_key => :foreign_key_field_description_id
  
  validates_presence_of :dataset_description, :relation_type, :relationship_dataset_description_id
  validates_uniqueness_of :dataset_description_id, :scope => [:relation_type, :relationship_dataset_description_id]
  
  def relation_table_exists?
    Dataset::DatasetRecord.connection.table_exists?("rel_#{dataset_description.identifier}_#{relationship_dataset_description.identifier}") || 
    Dataset::DatasetRecord.connection.table_exists?("rel_#{relationship_dataset_description.identifier}_#{dataset_description.identifier}")
  end
  
  def locate_relation_table_name
    [ "rel_#{dataset_description.identifier}_#{relationship_dataset_description.identifier}", 
      "rel_#{relationship_dataset_description.identifier}_#{dataset_description.identifier}"].each do |relation_table_name|
        return relation_table_name if Dataset::DatasetRecord.connection.table_exists?(relation_table_name)  
    end
    nil
  end
end
