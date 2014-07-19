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

ActiveRecord::Schema.define(:version => 20131117180746) do

  create_table "dc_relations", :primary_key => "_record_id", :force => true do |t|
    t.integer "relatable_left_id"
    t.string  "relatable_left_type"
    t.integer "relatable_right_id"
    t.string  "relatable_right_type"
    t.boolean "morphed"
  end

  add_index "dc_relations", ["relatable_left_type", "relatable_left_id"], :name => "index_relatable_left"
  add_index "dc_relations", ["relatable_right_type", "relatable_right_id"], :name => "index_relatable_right"

  create_table "dc_updates", :primary_key => "_record_id", :force => true do |t|
    t.integer  "updatable_id",   :null => false
    t.string   "updatable_type", :null => false
    t.string   "updated_column"
    t.text     "original_value"
    t.text     "new_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dc_updates", ["updatable_type", "updatable_id"], :name => "index_dc_updates_on_updatable_type_and_updatable_id"

  create_table "ds_executors", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "telephone"
    t.string   "fax"
    t.string   "email"
    t.string   "street"
    t.string   "zip"
    t.string   "city"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  create_table "ds_lawyer_associates", :primary_key => "_record_id", :force => true do |t|
    t.string   "original_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.integer  "sak_id",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  add_index "ds_lawyer_associates", ["original_name"], :name => "index_ds_lawyer_associates_on_original_name"
  add_index "ds_lawyer_associates", ["sak_id"], :name => "index_ds_lawyer_associates_on_sak_id"

  create_table "ds_lawyer_partnerships", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "partnership_type"
    t.string   "registry_number"
    t.integer  "ico"
    t.integer  "dic"
    t.string   "street"
    t.string   "city"
    t.integer  "zip"
    t.string   "phone"
    t.string   "fax"
    t.string   "cell_phone"
    t.string   "email"
    t.string   "website"
    t.integer  "sak_id"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  add_index "ds_lawyer_partnerships", ["sak_id"], :name => "index_ds_lawyer_partnerships_on_sak_id"

  create_table "ds_lawyers", :primary_key => "_record_id", :force => true do |t|
    t.string   "original_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "lawyer_type"
    t.string   "title"
    t.string   "street"
    t.string   "city"
    t.integer  "zip"
    t.string   "phone"
    t.string   "fax"
    t.string   "cell_phone"
    t.string   "languages"
    t.string   "email"
    t.string   "website"
    t.string   "url"
    t.datetime "etl_loaded"
    t.integer  "sak_id"
    t.boolean  "is_suspended"
    t.boolean  "is_state"
    t.boolean  "is_exoffo"
    t.boolean  "is_constitution"
    t.boolean  "is_asylum"
    t.string   "middle_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  add_index "ds_lawyers", ["sak_id"], :name => "index_ds_lawyers_on_sak_id"

  create_table "ds_notaries", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "form"
    t.string   "street"
    t.string   "city"
    t.string   "zip"
    t.integer  "doc_id"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  create_table "ds_notary_employees", :primary_key => "_record_id", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.date     "date_start"
    t.date     "date_end"
    t.string   "languages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  create_table "ds_organisations", :primary_key => "_record_id", :force => true do |t|
    t.integer  "id",                               :default => 0
    t.integer  "doc_id"
    t.integer  "ico",                 :limit => 8
    t.string   "name"
    t.string   "legal_form"
    t.integer  "legal_form_code"
    t.date     "date_start"
    t.date     "date_end"
    t.string   "address"
    t.string   "region"
    t.string   "activity1"
    t.integer  "activity1_code"
    t.string   "activity2"
    t.integer  "activity2_code"
    t.string   "account_sector"
    t.integer  "account_sector_code"
    t.string   "ownership"
    t.integer  "ownership_code"
    t.string   "size"
    t.integer  "size_code"
    t.string   "source_url"
    t.string   "quality_status"
    t.datetime "updated_at"
    t.integer  "batch_id"
    t.datetime "created_at"
    t.date     "validity_date"
    t.string   "created_by"
    t.boolean  "is_hidden"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "batch_record_code"
  end

  add_index "ds_organisations", ["account_sector"], :name => "account_sector_index"
  add_index "ds_organisations", ["activity1"], :name => "activity1_index"
  add_index "ds_organisations", ["activity2"], :name => "activity2_index"
  add_index "ds_organisations", ["address"], :name => "address_index"
  add_index "ds_organisations", ["date_end"], :name => "date_end_index"
  add_index "ds_organisations", ["date_start"], :name => "date_start_index"
  add_index "ds_organisations", ["ico"], :name => "ico_index"
  add_index "ds_organisations", ["legal_form"], :name => "legal_form_index"
  add_index "ds_organisations", ["name"], :name => "name_index"
  add_index "ds_organisations", ["ownership"], :name => "ownership_index"
  add_index "ds_organisations", ["region"], :name => "region_index"
  add_index "ds_organisations", ["size"], :name => "size_index"
  add_index "ds_organisations", ["source_url"], :name => "source_url_index"

  create_table "ds_otvorenezmluvy", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "otvorenezmluvy_type"
    t.string   "department"
    t.string   "customer"
    t.string   "supplier"
    t.integer  "supplier_ico"
    t.decimal  "contracted_amount",   :precision => 10, :scale => 2
    t.decimal  "total_amount",        :precision => 10, :scale => 2
    t.date     "published_on"
    t.date     "effective_from"
    t.date     "expires_on"
    t.text     "note"
    t.integer  "page_count"
    t.string   "source_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
  end

  create_table "ds_relation_testings", :primary_key => "_record_id", :force => true do |t|
    t.string   "created_by"
    t.string   "record_status"
    t.string   "updated_by"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.date     "validity_date"
    t.string   "quality_status"
    t.boolean  "is_hidden"
    t.integer  "batch_id"
    t.string   "test"
    t.integer  "ico"
    t.string   "company_name"
    t.string   "company_address"
    t.integer  "ds_testing_id"
  end

  add_index "ds_relation_testings", ["test"], :name => "test_index"

  create_table "ds_testings", :primary_key => "_record_id", :force => true do |t|
    t.string   "created_by"
    t.string   "record_status"
    t.string   "updated_by"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.date     "validity_date"
    t.string   "quality_status"
    t.boolean  "is_hidden"
    t.integer  "batch_id"
    t.string   "test"
    t.integer  "ico"
    t.string   "company_name"
    t.string   "company_address"
    t.string   "id"
  end

  add_index "ds_testings", ["test"], :name => "test_index"

  create_table "rel_associates_partnerships", :primary_key => "_record_id", :force => true do |t|
    t.integer "ds_lawyer_partnership_id"
    t.integer "ds_associate_id"
  end

  create_table "rel_lawyers_associates", :primary_key => "_record_id", :force => true do |t|
    t.integer "ds_lawyer_id"
    t.integer "ds_associate_id"
  end

  create_table "rel_lawyers_partnerships", :primary_key => "_record_id", :force => true do |t|
    t.integer "ds_lawyer_id"
    t.integer "ds_lawyer_partnership_id"
  end

end
