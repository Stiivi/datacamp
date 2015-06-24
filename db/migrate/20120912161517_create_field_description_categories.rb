class CreateFieldDescriptionCategories < ActiveRecord::Migration
  def self.up
    add_column :field_descriptions, :field_description_category_id, :integer

    create_table :field_description_categories do |t|
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    FieldDescriptionCategory.create_translation_table! title: :string
  end

  def self.down
    remove_column :field_descriptions, :field_description_category_id
    FieldDescriptionCategory.drop_translation_table!
    drop_table :field_description_categories
  end
end
