class ChangeImportFilesColumns < ActiveRecord::Migration
  def self.up
    remove_column :import_files, :imported
    add_column :import_files, :status, :boolean
  end

  def self.down
    remove_column :import_files, :status
    add_column :import_files, :imported, :boolean
  end
end
