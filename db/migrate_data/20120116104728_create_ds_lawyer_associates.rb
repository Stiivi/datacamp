class CreateDsLawyerAssociates < ActiveRecord::Migration
  def self.up
    create_table :ds_lawyer_associates, primary_key: :_record_id do |t|
      t.string :original_name
      t.string :first_name
      t.string :last_name
      t.string :title
    end
    
    add_index :ds_lawyer_associates, :original_name
  end

  def self.down
    drop_table :ds_lawyer_associates
  end
end
