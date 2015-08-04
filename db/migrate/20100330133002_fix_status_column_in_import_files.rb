# -*- encoding : utf-8 -*-
class FixStatusColumnInImportFiles < ActiveRecord::Migration
  def self.up
    change_column :import_files, :status, :string, :default => "ready"
  end

  def self.down
    change_column :import_files, :status, :boolean
  end
end
