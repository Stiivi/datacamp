class AddCanBeDisabledQuickSearchToDatasetDescriptions < ActiveRecord::Migration
  def self.up
    add_column :dataset_descriptions, :can_be_disabled_in_quick_search, :boolean
  end

  def self.down
    remove_column :dataset_descriptions, :can_be_disabled_in_quick_search
  end
end
