class AddNameHistoryToStaRegisMain < ActiveRecord::Migration
  def self.up
    add_column :sta_regis_main, :name_history, :text
  end

  def self.down
    remove_column :sta_regis_main, :name_history
  end
end
