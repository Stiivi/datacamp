class AddPositionToDatasetDescriptions < ActiveRecord::Migration
  def self.up
    add_column :dataset_descriptions, :position, :integer, :default => 0
  end

  def self.down
    remove_column :dataset_descriptions, :position
  end
end
