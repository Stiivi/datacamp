class RemoveUnusedRelationFields < ActiveRecord::Migration
  def self.up
    remove_column :relations, :relation_type
    remove_column :relations, :foreign_key_field_description_id
    remove_column :relations, :relation_table_identifier
  end

  def self.down
    add_column :relations, :relation_type, :string
    add_column :relations, :foreign_key_field_description_id, :integer
    add_column :relations, :relation_table_identifier, :string
  end
end
