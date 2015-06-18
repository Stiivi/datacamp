class RemoveNumberOfHeaderLinesFromImportFiles < ActiveRecord::Migration
  def self.up
    remove_column :import_files, :number_of_header_lines
  end

  def self.down
    add_column :import_files, :number_of_header_lines, :integer
  end
end
