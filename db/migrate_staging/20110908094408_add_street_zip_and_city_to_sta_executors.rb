class AddStreetZipAndCityToStaExecutors < ActiveRecord::Migration
  def self.up
    add_column :sta_executors, :street, :string
    add_column :sta_executors, :zip, :string
    add_column :sta_executors, :city, :string
    
    remove_column :sta_executors, :address
  end

  def self.down
    remove_column :sta_executors, :city
    remove_column :sta_executors, :zip
    remove_column :sta_executors, :street
    
    add_column :sta_executors, :address
  end
end
