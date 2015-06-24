class AddChangeTypeToChanges < ActiveRecord::Migration
  def self.up
    add_column :changes, :change_type, :string, null: false
  end

  def self.down
    remove_column :changes, :change_type
  end
end
