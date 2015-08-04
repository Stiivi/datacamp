class RemoveDisablableForQuickSearch < ActiveRecord::Migration
  def change
    remove_column :dataset_descriptions, :can_be_disabled_in_quick_search
  end
end
