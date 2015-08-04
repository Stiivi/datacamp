class AddIndexToNameOnEtlConfigurations < ActiveRecord::Migration
  def self.up
    add_index :etl_configurations, :name
  end

  def self.down
    remove_index :etl_configurations, :name
  end
end
