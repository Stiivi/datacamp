class CreateBlocks < ActiveRecord::Migration
  def self.up
    create_table :blocks do |t|
      t.string :name
      t.string :title
      t.string :url
      t.boolean :is_enabled
      t.references :page

      t.timestamps
    end
  end

  def self.down
    drop_table :blocks
  end
end
