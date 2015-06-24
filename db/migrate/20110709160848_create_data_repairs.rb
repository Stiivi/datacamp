class CreateDataRepairs < ActiveRecord::Migration
  def self.up
    create_table :data_repairs do |t|
      t.string :repair_type
      t.string :status
      
      t.string :record_ids
      
      t.string :regis_table_name
      t.string :regis_ico_column
      t.string :regis_name_column
      t.string :regis_address_column

      t.string :target_table_name
      t.string :target_ico_column
      t.string :target_company_name_column
      t.string :target_company_address_column
      t.integer :repaired_records
      t.integer :records_to_repair

      t.timestamps
    end
  end

  def self.down
    drop_table :data_repairs
  end
end
