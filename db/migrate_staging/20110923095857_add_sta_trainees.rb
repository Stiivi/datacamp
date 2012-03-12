class AddStaTrainees < ActiveRecord::Migration
  def self.up
    create_table :sta_trainees do |t|
      t.string :first_name
      t.string :last_name
      t.string :title
      t.integer :advokat_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sta_trainees
  end
end
