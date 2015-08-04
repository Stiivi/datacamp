# -*- encoding : utf-8 -*-
class AddApiColumns < ActiveRecord::Migration
  def self.up
    add_column :dataset_descriptions, :api_access_level, :integer, :default => 0
    add_column :users, :api_access_level, :integer, :default => 0
  end

  def self.down
    remove_column :users, :api_access_level
    remove_column :dataset_descriptions, :api_access_level
  end
end
