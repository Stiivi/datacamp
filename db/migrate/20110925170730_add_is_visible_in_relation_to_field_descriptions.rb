class AddIsVisibleInRelationToFieldDescriptions < ActiveRecord::Migration
  def self.up
    add_column :field_descriptions, :is_visible_in_relation, :boolean
  end

  def self.down
    remove_column :field_descriptions, :is_visible_in_relation
  end
end
