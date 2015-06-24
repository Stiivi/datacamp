class ChangeIsActiveOnDatasetDescriptions < ActiveRecord::Migration
  def self.up
    change_column :dataset_descriptions, :is_active, :boolean, default: 0
  end

  def self.down
    change_column :dataset_descriptions, :is_active, :boolean, default: 1
  end
end
