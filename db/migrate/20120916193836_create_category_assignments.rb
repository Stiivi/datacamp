class CreateCategoryAssignments < ActiveRecord::Migration
  def self.up
    create_table :category_assignments do |t|
      t.references :dataset_description
      t.references :field_description_category

      t.timestamps
    end
  end

  def self.down
    drop_table :category_assignments
  end
end
