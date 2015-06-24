class CreateDcRelations < ActiveRecord::Migration
  def self.up
    create_table :dc_relations, primary_key: :_record_id do |t|
      t.references :relatable_left, polymorphic: true
      t.references :relatable_right, polymorphic: true
    end
    
    add_index :dc_relations, [:relatable_left_type, :relatable_left_id], name: 'index_relatable_left'
    add_index :dc_relations, [:relatable_right_type, :relatable_right_id], name: 'index_relatable_right'
  end

  def self.down
    drop_table :dc_relations
  end
end
