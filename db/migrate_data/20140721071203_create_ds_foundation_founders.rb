class CreateDsFoundationFounders < ActiveRecord::Migration
  def self.up
    create_table :ds_foundation_founders, primary_key: :_record_id do |t|
      t.string :name
      t.string :identification_number
      t.string :address

      t.decimal :contribution_value
      t.string :contribution_currency
      t.string :contribution_subject
    end

    add_index :ds_foundation_founders, [:name, :address]
  end

  def self.down
    drop_table :ds_foundation_founders
  end
end
