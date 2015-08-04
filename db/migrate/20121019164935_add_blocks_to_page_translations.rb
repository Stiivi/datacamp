class AddBlocksToPageTranslations < ActiveRecord::Migration
  def self.up
    add_column :page_translations, :block, :text
  end

  def self.down
    remove_column :page_translations, :block
  end
end
