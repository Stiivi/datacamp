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

ActiveRecord::Schema.define(:version => 20150201162746) do

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

  create_table "ds_mzvsr_contracts", :primary_key => "_record_id", :force => true do |t|
    t.string   "uri",             :limit => 1024, :null => false
    t.string   "title_sk",        :limit => 2048, :null => false
    t.string   "title_en",        :limit => 2048
    t.string   "administrator"
    t.string   "place"
    t.string   "type"
    t.string   "country"
    t.date     "signed_on"
    t.date     "valid_from"
    t.string   "law_index"
    t.boolean  "priority"
    t.string   "protocol_number"
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

  add_index "ds_mzvsr_contracts", ["title_sk"], :name => "index_ds_mzvsr_contracts_on_title_sk", :length => {"title_sk"=>255}

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

  create_table "ds_procurement_v2_notices", :primary_key => "_record_id", :force => true do |t|
    t.integer  "document_id",                                                        :null => false
    t.string   "document_url",                                                       :null => false
    t.string   "procurement_code",                                                   :null => false
    t.integer  "bulletin_code",                                                      :null => false
    t.integer  "year",                                                               :null => false
    t.string   "procurement_type",                                                   :null => false
    t.date     "published_on",                                                       :null => false
    t.string   "customer_name"
    t.string   "customer_organisation_code"
    t.integer  "customer_organisation_id"
    t.string   "customer_regis_name"
    t.string   "customer_address"
    t.string   "customer_place"
    t.string   "customer_zip"
    t.string   "customer_country"
    t.string   "customer_contact_persons"
    t.string   "customer_phone"
    t.string   "customer_mobile"
    t.string   "customer_email"
    t.string   "customer_fax"
    t.string   "customer_type"
    t.boolean  "customer_purchase_for_others"
    t.text     "customer_main_activity"
    t.text     "project_name"
    t.string   "project_type"
    t.string   "project_category"
    t.text     "place_of_performance"
    t.string   "nuts_code"
    t.text     "project_description"
    t.boolean  "general_contract"
    t.text     "dictionary_main_subjects"
    t.text     "dictionary_additional_subjects"
    t.boolean  "gpa_agreement"
    t.string   "procedure_type"
    t.text     "procedure_offers_criteria"
    t.boolean  "procedure_use_auction"
    t.string   "previous_notification1_number"
    t.date     "previous_notification1_published_on"
    t.string   "previous_notification2_number"
    t.date     "previous_notification2_published_on"
    t.string   "previous_notification3_number"
    t.date     "previous_notification3_published_on"
    t.text     "contract_name"
    t.date     "contract_date"
    t.integer  "offers_total_count"
    t.integer  "offers_online_count"
    t.integer  "offers_excluded_count"
    t.integer  "supplier_index"
    t.string   "supplier_name"
    t.string   "supplier_organisation_code"
    t.integer  "supplier_organisation_id"
    t.string   "supplier_regis_name"
    t.string   "supplier_address"
    t.string   "supplier_place"
    t.string   "supplier_zip"
    t.string   "supplier_country"
    t.string   "supplier_phone"
    t.string   "supplier_mobile"
    t.string   "supplier_email"
    t.string   "supplier_fax"
    t.string   "procurement_currency"
    t.decimal  "final_price",                         :precision => 16, :scale => 2
    t.boolean  "final_price_range"
    t.decimal  "final_price_min",                     :precision => 16, :scale => 2
    t.decimal  "final_price_max",                     :precision => 16, :scale => 2
    t.boolean  "final_price_vat_included"
    t.decimal  "final_price_vat_rate",                :precision => 16, :scale => 2
    t.decimal  "draft_price",                         :precision => 16, :scale => 2
    t.boolean  "draft_price_vat_included"
    t.decimal  "draft_price_vat_rate",                :precision => 16, :scale => 2
    t.boolean  "procurement_subcontracted"
    t.boolean  "procurement_euro_found"
    t.text     "evaluation_committee"
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

  add_index "ds_procurement_v2_notices", ["customer_organisation_id"], :name => "index_ds_procurement_v2_notices_on_customer_organisation_id"
  add_index "ds_procurement_v2_notices", ["document_id", "supplier_index"], :name => "index_ds_procurement_v2_notices_on_document_id_and_supplier"
  add_index "ds_procurement_v2_notices", ["document_id"], :name => "index_ds_procurement_v2_notices_on_document_id"
  add_index "ds_procurement_v2_notices", ["supplier_organisation_id"], :name => "index_ds_procurement_v2_notices_on_supplier_organisation_id"

  create_table "ds_procurement_v2_performances", :primary_key => "_record_id", :force => true do |t|
    t.integer "document_id",                                                  :null => false
    t.string  "document_url",                                                 :null => false
    t.string  "procurement_code",                                             :null => false
    t.integer "bulletin_code",                                                :null => false
    t.integer "year",                                                         :null => false
    t.string  "procurement_type",                                             :null => false
    t.date    "published_on",                                                 :null => false
    t.string  "project_type"
    t.string  "customer_name"
    t.string  "customer_organisation_code"
    t.integer "customer_organisation_id"
    t.string  "customer_regis_name"
    t.string  "customer_address"
    t.string  "customer_place"
    t.string  "customer_zip"
    t.string  "customer_country"
    t.string  "customer_contact_persons"
    t.string  "customer_phone"
    t.string  "customer_mobile"
    t.string  "customer_email"
    t.string  "customer_fax"
    t.text    "contract_name"
    t.date    "contract_date"
    t.boolean "subject_delivered"
    t.text    "subcontract_name"
    t.date    "subcontract_date"
    t.text    "subcontract_reason"
    t.string  "procurement_currency"
    t.decimal "final_price",                   :precision => 16, :scale => 2
    t.boolean "final_price_vat_included"
    t.decimal "final_price_vat_rate",          :precision => 16, :scale => 2
    t.decimal "draft_price",                   :precision => 16, :scale => 2
    t.boolean "draft_price_vat_included"
    t.decimal "draft_price_vat_rate",          :precision => 16, :scale => 2
    t.text    "price_difference_reason"
    t.date    "start_on"
    t.date    "end_on"
    t.integer "duration"
    t.string  "duration_unit"
    t.text    "duration_difference_reason"
    t.string  "eu_notification_number"
    t.date    "eu_notification_published_on"
    t.string  "vvo_notification_number"
    t.date    "vvo_notification_published_on"
  end

  add_index "ds_procurement_v2_performances", ["customer_organisation_id"], :name => "index_ds_procurement_v2_performances_on_customer_organisation_id"
  add_index "ds_procurement_v2_performances", ["document_id"], :name => "index_ds_procurement_v2_performances_on_document_id"

  create_table "ds_projects", :primary_key => "_record_id", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
    t.string   "record_status"
    t.string   "quality_status"
    t.integer  "batch_id"
    t.date     "validity_date"
    t.boolean  "is_hidden"
    t.integer  "name"
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
