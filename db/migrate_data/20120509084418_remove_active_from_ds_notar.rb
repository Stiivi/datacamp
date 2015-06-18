class RemoveActiveFromDsNotar < ActiveRecord::Migration
  def self.up
    remove_column :ds_notaries, :active
  end

  def self.down
    add_column :ds_notaries, :active, :boolean, default: false
  end
end
