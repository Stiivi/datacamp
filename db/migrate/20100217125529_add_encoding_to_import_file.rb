class AddEncodingToImportFile < ActiveRecord::Migration
  def self.up
    add_column :import_files, :encoding, :string
  end

  def self.down
    remove_column :import_files, :encoding
  end
end
