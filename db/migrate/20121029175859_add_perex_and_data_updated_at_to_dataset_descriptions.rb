class AddPerexAndDataUpdatedAtToDatasetDescriptions < ActiveRecord::Migration
  def self.up
    add_column :dataset_description_translations, :perex, :text
    add_column :dataset_descriptions, :data_updated_at, :datetime
  end

  def self.down
    remove_column :dataset_descriptions, :data_updated_at
    remove_column :dataset_descriptions, :perex
  end
end
