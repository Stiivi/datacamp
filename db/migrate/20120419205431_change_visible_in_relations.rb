class ChangeVisibleInRelations < ActiveRecord::Migration
  def self.up
    change_column :field_descriptions, :is_visible_in_relation, :boolean, default: true
  end

  def self.down
    change_column :field_descriptions, :is_visible_in_relation, :boolean
  end
end
