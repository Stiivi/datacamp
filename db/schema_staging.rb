# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131117174618) do

  create_table "sta_advokats", :force => true do |t|
    t.string   "name"
    t.string   "avokat_type"
    t.string   "street"
    t.string   "city"
    t.string   "zip"
    t.string   "phone"
    t.string   "fax"
    t.string   "cell_phone"
    t.string   "languages"
    t.string   "email"
    t.string   "website"
    t.string   "url"
    t.datetime "etl_loaded"
  end

  create_table "sta_employees", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.date     "date_start"
    t.date     "date_end"
    t.string   "languages"
    t.integer  "sta_notar_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sta_executors", :force => true do |t|
    t.string "name"
    t.string "telephone"
    t.string "fax"
    t.string "email"
    t.string "street"
    t.string "zip"
    t.string "city"
  end

  create_table "sta_notaries", :force => true do |t|
    t.string  "name"
    t.string  "form"
    t.string  "street"
    t.string  "city"
    t.string  "zip"
    t.string  "worker_name"
    t.date    "date_start"
    t.date    "date_end"
    t.text    "languages"
    t.text    "open_hours"
    t.integer "doc_id"
    t.text    "url"
    t.boolean "active"
  end

  create_table "sta_procurements", :force => true do |t|
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
  end

  create_table "sta_procurements0508", :force => true do |t|
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
  end

  create_table "sta_procurements_0508", :force => true do |t|
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
  end

  create_table "sta_regis_account_sector", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "text"
  end

  add_index "sta_regis_account_sector", ["id"], :name => "i_account_sector"

  create_table "sta_regis_activity1", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "text"
  end

  add_index "sta_regis_activity1", ["id"], :name => "i_activity1"

  create_table "sta_regis_activity2", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "text"
  end

  add_index "sta_regis_activity2", ["id"], :name => "i_activity2"

  create_table "sta_regis_legal_form", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "text"
    t.date    "date_start"
    t.date    "date_end"
  end

  add_index "sta_regis_legal_form", ["id"], :name => "i_legal_form"

  create_table "sta_regis_main", :force => true do |t|
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
    t.text     "name_history"
  end

  add_index "sta_regis_main", ["ico"], :name => "index2"

  create_table "sta_regis_ownership", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "text"
  end

  add_index "sta_regis_ownership", ["id"], :name => "i_ownership"

  create_table "sta_regis_size", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "text"
  end

  add_index "sta_regis_size", ["id"], :name => "i_size"

  create_table "sta_trainees", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.integer  "advokat_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "etl_loaded"
  end

end
