class AddStreetZipAndCityToDsExecutors < ActiveRecord::Migration
  def self.up
    add_column :ds_executors, :street, :string unless column_exists? :ds_executors, :street
    add_column :ds_executors, :zip, :string unless column_exists? :ds_executors, :zip
    add_column :ds_executors, :city, :string unless column_exists? :ds_executors, :city

    remove_column :ds_executors, :address if column_exists? :ds_executors, :address
  end

  def self.down
    remove_column :ds_executors, :city
    remove_column :ds_executors, :zip
    remove_column :ds_executors, :street

    add_column :ds_executors, :address
  end
end
