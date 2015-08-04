class CreateDsProcurementV2Performances < ActiveRecord::Migration
  def up
    create_table :ds_procurement_v2_performances, primary_key: :_record_id do |t|

      t.integer :document_id, null: false
      t.string :document_url, null: false

      # Basic information
      t.string :procurement_code, null: false
      t.integer :bulletin_code, null: false
      t.integer :year, null: false
      t.string :procurement_type, null: false
      t.date :published_on, null: false
      t.string :project_type

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

      # Performance information
      t.text :contract_name
      t.date :contract_date
      t.boolean :subject_delivered
      t.text :subcontract_name
      t.date :subcontract_date
      t.text :subcontract_reason

      # Final price
      t.string :procurement_currency
      t.float :final_price
      t.boolean :final_price_vat_included
      t.float :final_price_vat_rate
      # Draft price
      t.float :draft_price
      t.boolean :draft_price_vat_included
      t.float :draft_price_vat_rate
      t.text :price_difference_reason
      # Duration
      t.date :start_on
      t.date :end_on
      t.integer :duration
      t.string :duration_unit
      t.text :duration_difference_reason

      # Additional information
      t.string :eu_notification_number
      t.date :eu_notification_published_on
      t.string :vvo_notification_number
      t.date :vvo_notification_published_on
    end

    add_index :ds_procurement_v2_performances, :document_id
    add_index :ds_procurement_v2_performances, :customer_organisation_id
  end

  def down
    remove_index :ds_procurement_v2_performances, :document_id
    remove_index :ds_procurement_v2_performances, :customer_organisation_id
    drop_table :ds_procurement_v2_performances
  end
end
