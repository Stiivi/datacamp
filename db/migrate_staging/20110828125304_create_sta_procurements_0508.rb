class CreateStaProcurements0508 < ActiveRecord::Migration
  def self.up
    create_table :sta_procurements0508 do |t|
      t.integer "year"
      t.integer "bulletin_id"
      t.string  "procurement_id"
      t.integer "customer_ico"
      t.integer "supplier_ico"
      t.string  "procurement_subject"
      t.decimal "price",                              :precision => 16, :scale => 2
      t.string  "currency"
      t.boolean "is_VAT_included"
      t.text    "customer_ico_evidence"
      t.text    "supplier_ico_evidence"
      t.text    "subject_evidence"
      t.text    "price_evidence"
      t.integer "document_id",           :limit => 8
      t.integer "extract_id"
      t.string  "supplier_name"
      t.string  "customer_name"
    end unless table_exists? :sta_procurements0508
  end

  def self.down
    drop_table :sta_procurements0508
  end
end
