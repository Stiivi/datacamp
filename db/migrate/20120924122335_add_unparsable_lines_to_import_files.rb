class AddUnparsableLinesToImportFiles < ActiveRecord::Migration
  def self.up
    add_column :import_files, :unparsable_lines, :text
  end

  def self.down
    remove_column :import_files, :unparsable_lines
  end
end
