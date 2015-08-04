class AddIndexesToFoundations < ActiveRecord::Migration
  def change
    add_index :ds_foundation_trustees, [:name, :address, :trustee_from, :trustee_to], name: 'index_ds_foundation_trust_on_name_and_address_and_from_and_to'
    add_index :ds_foundation_liquidators, [:name, :address, :liquidator_from, :liquidator_to], name: 'index_ds_foundation_liquid_on_name_and_address_and_from_and_to'
  end
end
