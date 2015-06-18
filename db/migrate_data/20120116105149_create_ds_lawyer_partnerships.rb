class CreateDsLawyerPartnerships < ActiveRecord::Migration
  def self.up
    create_table :ds_lawyer_partnerships, primary_key: :_record_id do |t|
      t.string :name
      t.string :partnership_type
      t.string :registry_number
      t.integer :ico
      t.integer :dic
      
      t.string :street
      t.string :city
      t.integer :zip
      t.string :phone
      t.string :fax
      t.string :cell_phone
      t.string :email
      t.string :website
      
      t.integer :sak_id
      t.string :url
    end
    
    add_index :ds_lawyer_partnerships, :sak_id
  end

  def self.down
    drop_table :ds_lawyer_partnerships
  end
end
