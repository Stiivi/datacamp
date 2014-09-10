class CreateDsMzvsrContracts < ActiveRecord::Migration
  def self.up
    create_table :ds_mzvsr_contracts, primary_key: :_record_id do |t|
      t.string  :uri,           limit: 1024, null: false
      t.string  :title_sk,      limit: 2048, null: false
      t.string  :title_en,      limit: 2048
      t.string  :administrator
      t.string  :place
      t.string  :type
      t.string  :country
      t.date    :signed_on
      t.date    :valid_from
      t.string  :law_index
      t.boolean :priority
      t.string  :protocol_number
    end

    add_index :ds_mzvsr_contracts, :title_sk
  end

  def self.down
    drop_table   :ds_mzvsr_contracts
    remove_index :ds_mzvsr_contracts, :title_sk
  end
end
