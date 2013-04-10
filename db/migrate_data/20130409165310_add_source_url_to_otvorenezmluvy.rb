class AddSourceUrlToOtvorenezmluvy < ActiveRecord::Migration
  def self.up
    add_column :ds_otvorenezmluvy, :source_url, :string
  end

  def self.down
    remove_column :ds_otvorenezmluvy, :source_url
  end
end
