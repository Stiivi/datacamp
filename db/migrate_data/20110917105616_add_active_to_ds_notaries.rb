class AddActiveToDsNotaries < ActiveRecord::Migration
  def self.up
    add_column :ds_notaries, :active, :boolean
  end

  def self.down
    remove_column :ds_notaries, :active
  end
end
