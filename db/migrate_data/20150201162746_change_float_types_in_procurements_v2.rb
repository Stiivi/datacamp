class ChangeFloatTypesInProcurementsV2 < ActiveRecord::Migration
  def up
    change_column :ds_procurement_v2_notices, :final_price, :decimal,                  :precision => 16, :scale => 2
    change_column :ds_procurement_v2_notices, :final_price_min, :decimal,              :precision => 16, :scale => 2
    change_column :ds_procurement_v2_notices, :final_price_max, :decimal,              :precision => 16, :scale => 2
    change_column :ds_procurement_v2_notices, :final_price_vat_rate, :decimal,         :precision => 16, :scale => 2
    change_column :ds_procurement_v2_notices, :draft_price, :decimal,                  :precision => 16, :scale => 2
    change_column :ds_procurement_v2_notices, :draft_price_vat_rate, :decimal,         :precision => 16, :scale => 2

    change_column :ds_procurement_v2_performances, :final_price, :decimal,             :precision => 16, :scale => 2
    change_column :ds_procurement_v2_performances, :final_price_vat_rate, :decimal,    :precision => 16, :scale => 2
    change_column :ds_procurement_v2_performances, :draft_price, :decimal,             :precision => 16, :scale => 2
    change_column :ds_procurement_v2_performances, :draft_price_vat_rate, :decimal,    :precision => 16, :scale => 2
  end

  def down
    change_column :ds_procurement_v2_notices, :final_price, :float
    change_column :ds_procurement_v2_notices, :final_price_min, :float
    change_column :ds_procurement_v2_notices, :final_price_max, :float
    change_column :ds_procurement_v2_notices, :final_price_vat_rate, :float
    change_column :ds_procurement_v2_notices, :draft_price, :float
    change_column :ds_procurement_v2_notices, :draft_price_vat_rate, :float

    change_column :ds_procurement_v2_performances, :final_price, :float
    change_column :ds_procurement_v2_performances, :final_price_vat_rate, :float
    change_column :ds_procurement_v2_performances, :draft_price, :float
    change_column :ds_procurement_v2_performances, :draft_price_vat_rate, :float
  end
end
