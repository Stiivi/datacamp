class AddParserToEtlConfigurations < ActiveRecord::Migration
  def self.up
    add_column :etl_configurations, :parser, :boolean, null: false, default: false
  end

  def self.down
    remove_column :etl_configurations, :parser
  end
end
