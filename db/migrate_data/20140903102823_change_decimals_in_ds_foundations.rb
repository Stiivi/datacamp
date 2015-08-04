class ChangeDecimalsInDsFoundations < ActiveRecord::Migration
  def up
    change_column :ds_foundations, :assets_value, :decimal, precision: 10, scale: 2
    change_column :ds_foundation_founders, :contribution_value, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :ds_foundations, :assets_value, :decimal, precision: 10, scale: 0
    change_column :ds_foundation_founders, :contribution_value, :decimal, precision: 10, scale: 0
  end
end
