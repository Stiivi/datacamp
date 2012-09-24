class AddShowBadQualityDatasetsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :show_bad_quality_datasets, :boolean, null: false, default: false
  end

  def self.down
    remove_column :users, :show_bad_quality_datasets
  end
end
