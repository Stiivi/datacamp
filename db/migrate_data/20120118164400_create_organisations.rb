class CreateOrganisations < ActiveRecord::Migration
  def self.up
    create_table :ds_organisations, primary_key: :_record_id do |t|
      t.integer :doc_id
      t.integer :ico
      t.string :name
      t.string :legal_form
      t.integer :legal_form_code
      t.date :date_start
      t.date :date_end
      t.string :address
      t.string :region
      t.string :activity1
      t.integer :activity1_code
      t.string :activity2
      t.integer :activity2_code
      t.string :account_sector
      t.integer :account_sector_code
      t.string :ownership
      t.integer :ownership_code
      t.string :size
      t.integer :size_code
      t.string :source_url
    end unless table_exists? :ds_organisations
  end

  def self.down
    drop_table :ds_organisations
  end
end
