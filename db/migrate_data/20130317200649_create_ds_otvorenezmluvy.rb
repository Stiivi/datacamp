class CreateDsOtvorenezmluvy < ActiveRecord::Migration
  def self.up
    create_table :ds_otvorenezmluvy, primary_key: :_record_id do |t|
      t.string :name
      t.string :otvorenezmluvy_type
      t.string :department
      t.string :customer
      t.string :supplier
      t.integer :supplier_ico
      t.decimal :contracted_amount, precision: 10, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2
      t.date :published_on
      t.date :effective_from
      t.date :expires_on
      t.text :note
      t.integer :page_count
    end
  end

  def self.down
    drop_table :ds_otvorenezmluvy
  end
end
