class AddRelationTableIdentifierToRelations < ActiveRecord::Migration
  def self.up
    add_column :relations, :relation_table_identifier, :string
  end

  def self.down
    remove_column :relations, :relation_table_identifier
  end
end
