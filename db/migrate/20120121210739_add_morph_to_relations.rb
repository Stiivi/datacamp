class AddMorphToRelations < ActiveRecord::Migration
  def self.up
    add_column :relations, :morph, :boolean
  end

  def self.down
    remove_column :relations, :morph
  end
end
