class AddIndexIsActiveToDatasetDescriptions < ActiveRecord::Migration
  def change
    add_index :dataset_descriptions, :is_active
  end
end
