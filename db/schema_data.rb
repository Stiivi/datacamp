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

ActiveRecord::Schema.define(:version => 20140903103235) do

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

  create_table "ds_foundation_founders", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "identification_number"
    t.string   "address"
    t.decimal  "contribution_value",    :precision => 10, :scale => 2
    t.string   "contribution_currency"
    t.string   "contribution_subject"
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

  add_index "ds_foundation_founders", ["name", "address"], :name => "index_ds_foundation_founders_on_name_and_address"

  create_table "ds_foundation_liquidators", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.date     "liquidator_from"
    t.date     "liquidator_to"
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

  add_index "ds_foundation_liquidators", ["name", "address", "liquidator_from", "liquidator_to"], :name => "index_ds_foundation_liquid_on_name_and_address_and_from_and_to"
  add_index "ds_foundation_liquidators", ["name", "address"], :name => "index_ds_foundation_liquidators_on_name_and_address"

  create_table "ds_foundation_trustees", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.date     "trustee_from"
    t.date     "trustee_to"
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

  add_index "ds_foundation_trustees", ["name", "address", "trustee_from", "trustee_to"], :name => "index_ds_foundation_trust_on_name_and_address_and_from_and_to"
  add_index "ds_foundation_trustees", ["name", "address"], :name => "index_ds_foundation_trustees_on_name_and_address"

  create_table "ds_foundations", :primary_key => "_record_id", :force => true do |t|
    t.string   "name"
    t.string   "identification_number"
    t.string   "registration_number"
    t.string   "address"
    t.text     "objective"
    t.date     "date_start"
    t.date     "date_registration"
    t.date     "date_liquidation"
    t.date     "date_end"
    t.decimal  "assets_value",          :precision => 10, :scale => 2
    t.string   "assets_currency"
    t.string   "url"
    t.integer  "ives_id"
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

  add_index "ds_foundations", ["ives_id"], :name => "index_ds_foundations_on_ives_id", :unique => true

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
    t.integer "doc_id"
    t.integer "ico"
    t.string  "name"
    t.string  "legal_form"
    t.integer "legal_form_code"
    t.date    "date_start"
    t.date    "date_end"
    t.string  "address"
    t.string  "region"
    t.string  "activity1"
    t.integer "activity1_code"
    t.string  "activity2"
    t.integer "activity2_code"
    t.string  "account_sector"
    t.integer "account_sector_code"
    t.string  "ownership"
    t.integer "ownership_code"
    t.string  "size"
    t.integer "size_code"
    t.string  "source_url"
    t.text    "name_history"
  end

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

end
