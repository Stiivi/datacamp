class AddSakIdToDsLawyerAssociates < ActiveRecord::Migration
  def self.up
    add_column :ds_lawyer_associates, :sak_id, :integer, null: false
    
    add_index :ds_lawyer_associates, :sak_id
  end

  def self.down
    remove_column :ds_lawyer_associates, :sak_id
  end
end
