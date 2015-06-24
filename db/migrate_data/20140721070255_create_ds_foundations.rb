class CreateDsFoundations < ActiveRecord::Migration
  def self.up
    create_table :ds_foundations, primary_key: :_record_id do |t|
      t.string :name
      t.string :identification_number
      t.string :registration_number
      t.string :address
      t.text :objective

      t.date :date_start
      t.date :date_registration
      t.date :date_liquidation
      t.date :date_end

      t.decimal :assets_value
      t.string :assets_currency

      t.string :url
      t.integer :ives_id
    end

    add_index :ds_foundations, :ives_id, unique: true
  end

  def self.down
    drop_table :ds_foundations
  end
end
