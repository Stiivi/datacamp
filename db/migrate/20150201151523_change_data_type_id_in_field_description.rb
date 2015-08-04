class ChangeDataTypeIdInFieldDescription < ActiveRecord::Migration
  def up
    rename_column :field_descriptions, :data_type_id, :data_type
    change_column :field_descriptions, :data_type, :string
  end

  def down
    rename_column :field_descriptions, :data_type, :data_type_id
    change_column :field_descriptions, :data_type_id, :integer
  end
end
