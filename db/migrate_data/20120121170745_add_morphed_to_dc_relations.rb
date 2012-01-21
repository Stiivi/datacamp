class AddMorphedToDcRelations < ActiveRecord::Migration
  def self.up
    add_column :dc_relations, :morphed, :boolean
  end

  def self.down
    remove_column :dc_relations, :morphed
  end
end
