class CreateRelations < ActiveRecord::Migration
  def self.up
    create_table :relations do |t|
      t.references :dataset_description
      t.string :relation_type
      t.integer :relationship_dataset_description_id
      t.integer :foreign_key_field_description_id

      t.timestamps
    end
  end

  def self.down
    drop_table :relations
  end
end
