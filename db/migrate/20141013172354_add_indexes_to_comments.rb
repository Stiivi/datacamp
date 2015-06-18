class AddIndexesToComments < ActiveRecord::Migration
  def change
    add_index :comments, [:is_suspended, :dataset_description_id, :record_id], name: 'index_comments_on_is_suspend_and_dataset_description_and_record'
  end
end
