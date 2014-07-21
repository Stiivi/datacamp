class CreateDsFoundationTrustees < ActiveRecord::Migration
  def self.up
    create_table :ds_foundation_trustees, primary_key: :_record_id do |t|
      t.string :name
      t.string :address

      t.date :trustee_from
      t.date :trustee_to
    end

    add_index :ds_foundation_trustees, [:name, :address]
  end

  def self.down
    drop_table :ds_foundation_trustees
  end
end
