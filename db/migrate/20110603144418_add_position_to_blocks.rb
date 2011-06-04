class AddPositionToBlocks < ActiveRecord::Migration
  def self.up
    add_column :blocks, :position, :integer, :default => 0
  end

  def self.down
    remove_column :blocks, :position
  end
end
