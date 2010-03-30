class AddLinesImportedToImportFiles < ActiveRecord::Migration
  def self.up
    add_column :import_files, :count_of_imported_lines, :integer
  end

  def self.down
    remove_column :import_files, :count_of_imported_lines
  end
end
