class AddActiveToStaNotaries < ActiveRecord::Migration
  def self.up
    add_column :sta_notaries, :active, :boolean
  end

  def self.down
    remove_column :sta_notaries, :active
  end
end
