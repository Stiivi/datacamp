class DropRelationshipDescriptions < ActiveRecord::Migration
  def change
    drop_table :relationship_descriptions
  end
end
