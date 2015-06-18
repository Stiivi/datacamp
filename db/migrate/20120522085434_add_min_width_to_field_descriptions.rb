class AddMinWidthToFieldDescriptions < ActiveRecord::Migration
  def self.up
    add_column :field_descriptions, :min_width, :integer
  end

  def self.down
    remove_column :field_descriptions, :min_width
  end
end
