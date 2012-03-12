class CreateStaExecutors < ActiveRecord::Migration
  def self.up
    create_table :sta_executors do |t|
      t.string    :name
      t.string    :address
      t.string    :telephone
      t.string    :fax
      t.string    :email
    end unless table_exists? :sta_executors
  end

  def self.down
    drop_table :sta_executors
  end
end
