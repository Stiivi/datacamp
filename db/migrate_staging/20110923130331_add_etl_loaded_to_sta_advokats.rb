class AddEtlLoadedToStaAdvokats < ActiveRecord::Migration
  def self.up
    add_column :sta_advokats, :etl_loaded, :datetime
  end

  def self.down
    remove_column :sta_advokats, :etl_loaded
  end
end
