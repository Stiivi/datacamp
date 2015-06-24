class AddEtlLoadedToStaTrainees < ActiveRecord::Migration
  def self.up
    add_column :sta_trainees, :etl_loaded, :datetime
  end

  def self.down
    remove_column :sta_trainees, :etl_loaded
  end
end
