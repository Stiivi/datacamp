class CreateStaAdvokats < ActiveRecord::Migration
  def self.up
    create_table :sta_advokats do |t|
      t.string    :name
      t.string    :avokat_type
      t.string    :street
      t.string    :city
      t.string    :zip
      t.string    :phone
      t.string    :fax
      t.string    :cell_phone
      t.string    :languages
      t.string    :email
      t.string    :website
      t.string    :url
    end unless table_exists? :sta_advokats
  end

  def self.down
    drop_table :sta_advokats
  end
end
