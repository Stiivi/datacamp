class CreateDsFoundationLiquidators < ActiveRecord::Migration
  def self.up
    create_table :ds_foundation_liquidators, primary_key: :_record_id do |t|
      t.string :name
      t.string :address

      t.date :liquidator_from
      t.date :liquidator_to
    end

    add_index :ds_foundation_liquidators, [:name, :address]
  end

  def self.down
    drop_table :ds_foundation_liquidators
  end
end
