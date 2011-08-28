class CreateStaNotaries < ActiveRecord::Migration
  def self.up
    create_table :sta_notaries do |t|
       t.string    :name
       t.string    :form
       t.string    :street
       t.string    :city
       t.integer   :zip
       t.string    :worker_name
       t.date      :date_start
       t.date      :date_end
       t.text      :languages
       t.text      :open_hours
       t.integer   :doc_id
       t.text      :url
     end
  end

  def self.down
    drop_table :sta_notaries
  end
end
