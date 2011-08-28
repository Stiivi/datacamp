class CreateStaRegisMain < ActiveRecord::Migration
  def self.up
    create_table :sta_regis_main do |t|
      t.integer  "doc_id"
      t.integer  "ico",             :limit => 8
      t.string   "name"
      t.integer  "legal_form"
      t.date     "date_start"
      t.date     "date_end"
      t.string   "address"
      t.string   "region"
      t.integer  "activity1"
      t.integer  "activity2"
      t.integer  "account_sector"
      t.integer  "ownership"
      t.integer  "size"
      t.string   "source_url"
      t.datetime "date_created"
      t.datetime "etl_loaded_date"
      t.datetime "updated_at"
    end
    
    add_index "sta_regis_main", ["ico"], :name => "index2"
  end

  def self.down
    drop_table :sta_regis_main
  end
end
