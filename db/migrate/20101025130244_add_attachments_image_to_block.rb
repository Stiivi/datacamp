# -*- encoding : utf-8 -*-
class AddAttachmentsImageToBlock < ActiveRecord::Migration
  def self.up
    add_column :blocks, :image_file_name, :string
    add_column :blocks, :image_content_type, :string
    add_column :blocks, :image_file_size, :integer
    add_column :blocks, :image_updated_at, :datetime
  end

  def self.down
    remove_column :blocks, :image_file_name
    remove_column :blocks, :image_content_type
    remove_column :blocks, :image_file_size
    remove_column :blocks, :image_updated_at
  end
end
