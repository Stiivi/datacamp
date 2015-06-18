class CreateDsProcurementV2Notices < ActiveRecord::Migration
  def up
    create_table :ds_procurement_v2_notices, primary_key: :_record_id do |t|

      t.integer :document_id, null: false
      t.string :document_url, null: false

      # Basic information
      t.string :procurement_code, null: false
      t.integer :bulletin_code, null: false
      t.integer :year, null: false
      t.string :procurement_type, null: false
      t.date :published_on, null: false

      # Customer information
      t.string :customer_name
      t.string :customer_organisation_code
      t.integer :customer_organisation_id
      t.string :customer_regis_name
      t.string :customer_address
      t.string :customer_place
      t.string :customer_zip
      t.string :customer_country
      # Customer contact information
      t.string :customer_contact_persons
      t.string :customer_phone
      t.string :customer_mobile
      t.string :customer_email
      t.string :customer_fax
      t.string :customer_type
      t.boolean :customer_purchase_for_others
      t.text :customer_main_activity

      # Contract information
      t.text :project_name
      t.string :project_type
      t.string :project_category
      t.text :place_of_performance
      t.string :nuts_code
      t.text :project_description
      t.boolean :general_contract
      t.text :dictionary_main_subjects
      t.text :dictionary_additional_subjects
      t.boolean :gpa_agreement

      # Procedure information
      t.string :procedure_type
      t.text :procedure_offers_criteria
      t.boolean :procedure_use_auction
      t.string :previous_notification1_number
      t.date :previous_notification1_published_on
      t.string :previous_notification2_number
      t.date :previous_notification2_published_on
      t.string :previous_notification3_number
      t.date :previous_notification3_published_on

      # Supplier information
      t.text :contract_name
      t.date :contract_date
      t.integer :offers_total_count
      t.integer :offers_online_count
      t.integer :offers_excluded_count
      t.integer :supplier_index # for unique document
      t.string :supplier_name
      t.string :supplier_organisation_code
      t.integer :supplier_organisation_id
      t.string :supplier_regis_name
      t.string :supplier_address
      t.string :supplier_place
      t.string :supplier_zip
      t.string :supplier_country
      t.string :supplier_phone
      t.string :supplier_mobile
      t.string :supplier_email
      t.string :supplier_fax
      # Final price
      t.string :procurement_currency
      t.float :final_price
      t.boolean :final_price_range
      t.float :final_price_min
      t.float :final_price_max
      t.boolean :final_price_vat_included
      t.float :final_price_vat_rate
      # Draft price
      t.float :draft_price
      t.boolean :draft_price_vat_included
      t.float :draft_price_vat_rate
      t.boolean :procurement_subcontracted

      # Additional information
      t.boolean :procurement_euro_found
      t.text :evaluation_committee
    end

    add_index :ds_procurement_v2_notices, :document_id
    add_index :ds_procurement_v2_notices, :customer_organisation_id
    add_index :ds_procurement_v2_notices, :supplier_organisation_id
    add_index :ds_procurement_v2_notices, [:document_id, :supplier_index], name: 'index_ds_procurement_v2_notices_on_document_id_and_supplier'
  end

  def down
    remove_index :ds_procurement_v2_notices, :document_id
    remove_index :ds_procurement_v2_notices, :customer_organisation_id
    remove_index :ds_procurement_v2_notices, :supplier_organisation_id
    remove_index :ds_procurement_v2_notices, name: 'index_ds_procurement_v2_notices_on_document_id_and_supplier'
    drop_table :ds_procurement_v2_notices
  end
end
