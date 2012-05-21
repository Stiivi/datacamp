class ChangeDetailsTypeOnChanges < ActiveRecord::Migration
  def self.up
    change_column :changes, :change_details, :mediumtext
  end

  def self.down
    change_column :changes, :change_details, :text
  end
end
