class AddIndexDatasetDescriptionIdToDatasetDescriptionTranslation < ActiveRecord::Migration
  def change
    add_index :dataset_description_translations, :dataset_description_id
  end
end
