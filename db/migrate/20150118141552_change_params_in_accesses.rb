class ChangeParamsInAccesses < ActiveRecord::Migration
  def up
    change_column :accesses, :params, :text
  end

  def down
    change_column :accesses, :params, :string
  end
end
