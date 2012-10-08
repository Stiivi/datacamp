class AddDownloadPathToEtlConfigurations < ActiveRecord::Migration
  def self.up
    add_column :etl_configurations, :download_path, :string
  end

  def self.down
    remove_column :etl_configurations, :download_path
  end
end
