class CreateStaProcurements < ActiveRecord::Migration
  def self.up
    create_table :sta_procurements do |t|
      t.integer  "year"
      t.integer  "bulletin_id"
      t.string   "procurement_id"
      t.integer  "customer_ico",           :limit => 8
      t.integer  "supplier_ico",           :limit => 8
      t.text     "procurement_subject"
      t.decimal  "price",                               :precision => 16, :scale => 2
      t.string   "currency"
      t.boolean  "is_vat_included"
      t.text     "customer_ico_evidence"
      t.text     "supplier_ico_evidence"
      t.text     "subject_evidence"
      t.text     "price_evidence"
      t.integer  "procurement_type_id"
      t.integer  "document_id",            :limit => 8
      t.string   "source_url"
      t.datetime "date_created"
      t.datetime "etl_loaded_date"
      t.text     "supplier_name"
      t.text     "customer_name"
      t.boolean  "is_price_part_of_range"
      t.text     "note"
    end unless table_exists? :sta_procurements
  end

  def self.down
    drop_table :sta_procurements
  end
end
