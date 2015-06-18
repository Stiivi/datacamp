class CreateDsExecutors < ActiveRecord::Migration
  def self.up
    create_table :ds_executors, primary_key: :_record_id do |t|
      t.string    :name
      t.string    :address
      t.string    :telephone
      t.string    :fax
      t.string    :email
    end unless table_exists? :ds_executors
  end

  def self.down
    drop_table :ds_executors
  end
end
