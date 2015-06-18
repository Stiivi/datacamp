class AddNameHistoryToRegis < ActiveRecord::Migration
  def self.up
    add_column :ds_organisations, :name_history, :text
  end

  def self.down
    remove_column :ds_organisations, :name_history
  end
end
