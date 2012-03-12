class CreateStaRegisHelpers < ActiveRecord::Migration
  def self.up
    unless table_exists? "sta_regis_ownership"
      create_table "sta_regis_ownership", :id => false, :force => true do |t|
        t.integer "id"
        t.string  "text"
      end

      add_index "sta_regis_ownership", ["id"], :name => "i_ownership"
    end
    
    unless table_exists? "sta_regis_size"
      create_table "sta_regis_size", :id => false, :force => true do |t|
        t.integer "id"
        t.string  "text"
      end

      add_index "sta_regis_size", ["id"], :name => "i_size"
    end
    
    unless table_exists? "sta_regis_account_sector"
      create_table "sta_regis_account_sector", :id => false, :force => true do |t|
        t.integer "id"
        t.string  "text"
      end

      add_index "sta_regis_account_sector", ["id"], :name => "i_account_sector"
    end

    unless table_exists? "sta_regis_activity1"
      create_table "sta_regis_activity1", :id => false, :force => true do |t|
        t.integer "id"
        t.string  "text"
      end

      add_index "sta_regis_activity1", ["id"], :name => "i_activity1"
    end
    
    unless table_exists? "sta_regis_activity2"
      create_table "sta_regis_activity2", :id => false, :force => true do |t|
        t.integer "id"
        t.string  "text"
      end

      add_index "sta_regis_activity2", ["id"], :name => "i_activity2"
    end

    unless table_exists? "sta_regis_legal_form"
      create_table "sta_regis_legal_form", :id => false, :force => true do |t|
        t.integer "id"
        t.string  "text"
        t.date    "date_start"
        t.date    "date_end"
      end

      add_index "sta_regis_legal_form", ["id"], :name => "i_legal_form"
    end
  end

  def self.down
    drop_table :sta_regis_ownership
    drop_table :sta_regis_size
    drop_table :sta_regis_account_sector
    drop_table :sta_regis_activity1
    drop_table :sta_regis_activity2
    drop_table :sta_regis_legal_form
  end
end
