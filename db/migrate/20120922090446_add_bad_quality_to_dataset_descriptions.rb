class AddBadQualityToDatasetDescriptions < ActiveRecord::Migration
  def self.up
    add_column :dataset_descriptions, :bad_quality, :boolean, null: false, default: false
  end

  def self.down
    remove_column :dataset_descriptions, :bad_quality
  end
end
