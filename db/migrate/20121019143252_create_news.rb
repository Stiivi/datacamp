class CreateNews < ActiveRecord::Migration
  def self.up
    create_table :news do |t|
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    News.create_translation_table! title: :string, text: :text
  end

  def self.down
    News.drop_translation_table!
    drop_table :news
  end
end
