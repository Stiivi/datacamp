class AddLastRunTimeToEtlConfigurations < ActiveRecord::Migration
  def self.up
    add_column :etl_configurations, :last_run_time, :datetime
  end

  def self.down
    remove_column :etl_configurations, :last_run_time
  end
end
