class AddStatusToEtlConfigurations < ActiveRecord::Migration
  def self.up
    add_column :etl_configurations, :status, :string
  end

  def self.down
    remove_column :etl_configurations, :status
  end
end
