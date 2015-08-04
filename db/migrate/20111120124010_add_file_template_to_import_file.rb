class AddFileTemplateToImportFile < ActiveRecord::Migration
  def self.up
    add_column :import_files, :file_template, :string
  end

  def self.down
    remove_column :import_files, :file_template
  end
end
