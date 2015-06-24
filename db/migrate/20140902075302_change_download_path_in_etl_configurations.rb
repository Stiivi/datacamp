class ChangeDownloadPathInEtlConfigurations < ActiveRecord::Migration
  def up
    change_column :etl_configurations, :download_path, :text
  end

  def down
    change_column :etl_configurations, :download_path, :string
  end
end
