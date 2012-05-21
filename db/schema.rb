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

ActiveRecord::Schema.define(:version => 20120521110136) do

  create_table "access_rights", :force => true do |t|
    t.string   "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
  end

  create_table "access_role_rights", :id => false, :force => true do |t|
    t.integer  "access_role_id"
    t.integer  "access_right_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "access_roles", :force => true do |t|
    t.string   "title"
    t.string   "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accesses", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "record_id"
    t.integer  "dataset_description_id"
    t.integer  "session_id"
    t.string   "params"
    t.string   "url"
    t.string   "controller"
    t.string   "action"
    t.string   "referrer"
    t.string   "http_method"
  end

  create_table "api_keys", :force => true do |t|
    t.integer  "user_id"
    t.string   "key"
    t.boolean  "is_valid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "batches", :force => true do |t|
    t.string   "batch_type"
    t.string   "batch_source"
    t.string   "data_source_name"
    t.string   "data_source_url"
    t.date     "valid_due_date"
    t.date     "batch_date"
    t.string   "username"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "blocks", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.string   "url"
    t.boolean  "is_enabled"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "position",           :default => 0
  end

  create_table "changes", :force => true do |t|
    t.string   "dataset_description_id"
    t.string   "record_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "change_type",                                   :null => false
    t.text     "dataset_description_cache"
    t.text     "change_details",            :limit => 16777215
  end

  create_table "comment_ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "comment_id"
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comment_reports", :force => true do |t|
    t.integer  "comment_id"
    t.integer  "user_id"
    t.string   "type"
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "title"
    t.text     "text"
    t.integer  "user_id"
    t.integer  "dataset_description_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_staff"
    t.integer  "parent_comment_id"
    t.boolean  "is_suspended"
    t.integer  "record_id"
    t.integer  "count_positive_ratings"
    t.integer  "count_negative_ratings"
  end

  create_table "data_formats", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_repairs", :force => true do |t|
    t.string   "repair_type"
    t.string   "status"
    t.string   "record_ids"
    t.string   "regis_table_name"
    t.string   "regis_ico_column"
    t.string   "regis_name_column"
    t.string   "regis_address_column"
    t.string   "target_table_name"
    t.string   "target_ico_column"
    t.string   "target_company_name_column"
    t.string   "target_company_address_column"
    t.integer  "repaired_records"
    t.integer  "records_to_repair"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dataset_categories", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",   :default => 0
  end

  create_table "dataset_category_translations", :force => true do |t|
    t.integer  "dataset_category_id"
    t.string   "locale"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dataset_description_translations", :force => true do |t|
    t.integer  "dataset_description_id"
    t.string   "locale"
    t.text     "description"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dataset_descriptions", :force => true do |t|
    t.string   "identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "database"
    t.integer  "format_rule_id"
    t.string   "data_provider"
    t.string   "update_frequency"
    t.string   "keywords"
    t.string   "unit_of_analysis"
    t.string   "granularity"
    t.string   "collection_mode"
    t.string   "data_source_type"
    t.integer  "category_id"
    t.boolean  "is_active",                       :default => false
    t.string   "default_import_format"
    t.integer  "api_access_level",                :default => 0
    t.boolean  "can_be_disabled_in_quick_search"
    t.integer  "position",                        :default => 0
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "delayed_jobs_locked_by"
  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "etl_configurations", :force => true do |t|
    t.string   "name"
    t.integer  "start_id"
    t.integer  "batch_limit"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "last_processed_id"
    t.datetime "last_run_time"
  end

  create_table "favorites", :force => true do |t|
    t.integer  "dataset_description_id"
    t.integer  "record_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "note"
  end

  create_table "field_description_translations", :force => true do |t|
    t.integer  "field_description_id"
    t.string   "locale"
    t.string   "category"
    t.text     "description"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "field_descriptions", :force => true do |t|
    t.integer "dataset_description_id"
    t.string  "identifier"
    t.integer "weight"
    t.integer "format_rule_id"
    t.boolean "importable",             :default => false
    t.integer "importable_column"
    t.integer "data_type_id"
    t.boolean "is_visible_in_listing",  :default => true
    t.boolean "is_derived"
    t.string  "derived_value"
    t.boolean "is_visible_in_search",   :default => true
    t.boolean "is_visible_in_detail",   :default => true
    t.boolean "is_visible_in_export",   :default => true
    t.integer "data_format_id"
    t.string  "data_format_argument"
    t.string  "reference"
    t.boolean "is_visible_in_relation", :default => true
  end

  create_table "import_files", :force => true do |t|
    t.string   "title"
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_description_id"
    t.string   "path_file_name"
    t.string   "path_content_type"
    t.integer  "path_file_size"
    t.datetime "path_updated_at"
    t.string   "col_separator",           :default => ","
    t.integer  "identifier_line"
    t.string   "encoding"
    t.integer  "count_of_imported_lines"
    t.string   "status",                  :default => "ready"
    t.string   "file_template"
  end

  create_table "known_datacamps", :force => true do |t|
    t.string   "url"
    t.string   "name"
    t.string   "owner"
    t.string   "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_translations", :force => true do |t|
    t.integer  "page_id"
    t.string   "locale"
    t.text     "body"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.string   "page_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "quality_statuses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
  end

  create_table "relations", :force => true do |t|
    t.integer  "dataset_description_id"
    t.integer  "relationship_dataset_description_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "morph"
  end

  create_table "relationship_description_translations", :force => true do |t|
    t.integer  "relationship_description_id"
    t.string   "locale"
    t.string   "category"
    t.text     "description"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationship_descriptions", :force => true do |t|
    t.integer "dataset_description_id"
    t.integer "target_dataset_description_id"
    t.boolean "is_to_many"
    t.string  "identifier"
    t.integer "weight"
  end

  create_table "search_predicates", :force => true do |t|
    t.integer "search_query_id"
    t.string  "scope"
    t.string  "search_field"
    t.string  "operator"
    t.string  "argument"
  end

  create_table "search_queries", :force => true do |t|
    t.text     "query_yaml"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "scope"
    t.string   "object"
  end

  create_table "search_results", :force => true do |t|
    t.integer  "search_query_id"
    t.string   "table_name"
    t.integer  "record_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_results", ["search_query_id", "table_name"], :name => "find_for_show"

  create_table "searches", :force => true do |t|
    t.integer  "search_query_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "query_string"
    t.integer  "session_id"
    t.string   "search_type"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remote_ip"
  end

  create_table "sharing_services", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image"
  end

  create_table "system_variable_translations", :force => true do |t|
    t.integer  "system_variable_id"
    t.string   "locale"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "system_variables", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tmp_names", :id => false, :force => true do |t|
    t.text "NAME"
    t.text "sex"
  end

  create_table "tmp_surnames", :id => false, :force => true do |t|
    t.text "surname"
  end

  create_table "user_access_rights", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "access_right_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_access_roles", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "access_role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.integer  "user_role_id"
    t.float    "score"
    t.text     "about"
    t.string   "loc"
    t.string   "restoration_code"
    t.boolean  "is_super_user"
    t.integer  "records_per_page"
    t.integer  "api_access_level",                         :default => 0
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "watchers", :force => true do |t|
    t.string   "email"
    t.string   "organization"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
