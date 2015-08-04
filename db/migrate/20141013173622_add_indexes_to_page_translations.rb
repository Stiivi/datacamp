class AddIndexesToPageTranslations < ActiveRecord::Migration
  def change
    add_index :page_translations, :page_id
  end
end
