class CreateStaEmployees < ActiveRecord::Migration
  def self.up
    create_table :sta_employees do |t|
      t.string :first_name
      t.string :last_name
      t.string :title
      t.date :date_start
      t.date :date_end
      t.string :languages
      t.integer :sta_notar_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sta_employees
  end
end
