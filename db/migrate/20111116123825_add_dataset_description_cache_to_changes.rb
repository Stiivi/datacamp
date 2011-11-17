class AddDatasetDescriptionCacheToChanges < ActiveRecord::Migration
  def self.up
    add_column :changes, :dataset_description_cache, :text
  end

  def self.down
    remove_column :changes, :dataset_description_cache
  end
end
