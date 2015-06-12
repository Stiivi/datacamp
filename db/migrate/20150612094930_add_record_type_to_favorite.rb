class AddRecordTypeToFavorite < ActiveRecord::Migration
  def change
    add_column :favorites, :record_type, :string
  end
end
