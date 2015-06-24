class CreateDcUpdates < ActiveRecord::Migration
  def self.up
    create_table :dc_updates, primary_key: :_record_id do |t|
      t.references :updatable, polymorphic: true, null: false
      t.string :updated_column
      t.text :original_value
      t.text :new_value
      
      t.timestamps
    end
    
    add_index :dc_updates, [:updatable_type, :updatable_id]
  end

  def self.down
    drop_table :dc_updates
  end
end
