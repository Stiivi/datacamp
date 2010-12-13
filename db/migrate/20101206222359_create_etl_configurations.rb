# -*- encoding : utf-8 -*-
class CreateEtlConfigurations < ActiveRecord::Migration
  def self.up
    create_table :etl_configurations do |t|
      t.string :name
      t.integer :start_id
      t.integer :batch_limit

      t.timestamps
    end
  end

  def self.down
    drop_table :etl_configurations
  end
end
