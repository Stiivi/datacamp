# -*- encoding : utf-8 -*-
class AddLastProcessedIdToEtlConfigurations < ActiveRecord::Migration
  def self.up
    add_column :etl_configurations, :last_processed_id, :integer
  end

  def self.down
    remove_column :etl_configurations, :last_processed_id
  end
end
