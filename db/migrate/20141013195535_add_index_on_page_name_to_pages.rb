class AddIndexOnPageNameToPages < ActiveRecord::Migration
  def change
    add_index :pages, :page_name
  end
end
