class CreateDsNotaries < ActiveRecord::Migration
  def self.up
    create_table :ds_notaries, primary_key: :_record_id  do |t|
       t.string    :name
       t.string    :form
       t.string    :street
       t.string    :city
       t.string    :zip
       t.integer   :doc_id
       t.text      :url
     end unless table_exists? :ds_notaries
  end

  def self.down
    drop_table :ds_notaries
  end
end
