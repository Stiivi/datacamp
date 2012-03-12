class RenameFieldColumns < ActiveRecord::Migration
  def self.up
    rename_column(:search_predicates, :field, :search_field)
    rename_column(:changes, :field, :changed_field)
  end

  def self.down
    rename_column(:search_predicated, :search_field, :field)
    rename_column(:changes, :changed_field, :field)
  end
end
