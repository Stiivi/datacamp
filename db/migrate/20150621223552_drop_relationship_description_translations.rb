class DropRelationshipDescriptionTranslations < ActiveRecord::Migration
  def change
    drop_table :relationship_description_translations
  end
end
