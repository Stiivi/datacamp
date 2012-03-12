class CreateDsLawyers < ActiveRecord::Migration
  def self.up
    create_table :ds_lawyers, primary_key: :_record_id do |t|
      t.string :original_name
      t.string :first_name
      t.string :last_name

      t.string :lawyer_type
      t.string :title
      t.string :street
      t.string :city
      t.integer :zip
      t.string :phone
      t.string :fax
      t.string :cell_phone
      t.string :languages
      t.string :email
      t.string :website
      t.string :url
      t.timestamp :etl_loaded
      t.integer :sak_id
      
      t.boolean :is_suspended
      t.boolean :is_state
      t.boolean :is_exoffo
      t.boolean :is_constitution
      t.boolean :is_asylum
    end
    
    add_index :ds_lawyers, :sak_id
  end

  def self.down
    drop_table :ds_lawyers
  end
end
