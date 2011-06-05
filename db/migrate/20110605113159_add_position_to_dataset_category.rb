class AddPositionToDatasetCategory < ActiveRecord::Migration
  def self.up
    add_column :dataset_categories, :position, :integer, :default => 0
  end

  def self.down
    remove_column :dataset_categories, :position
  end
end
