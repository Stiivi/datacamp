class AddMiddleNameToLawyers < ActiveRecord::Migration
  def self.up
    add_column :ds_lawyers, :middle_name, :string
  end

  def self.down
    remove_column :ds_lawyers, :middle_name
  end
end
