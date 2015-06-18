class CreateDsNotaryEmployees < ActiveRecord::Migration
  def self.up
    create_table :ds_notary_employees, primary_key: :_record_id  do |t|
      t.string :first_name
      t.string :last_name
      t.string :title
      t.date :date_start
      t.date :date_end
      t.string :languages
    end
  end

  def self.down
    drop_table :ds_notary_employees
  end
end
