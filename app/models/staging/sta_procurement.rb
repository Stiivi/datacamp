# -*- encoding : utf-8 -*-
module Staging
  class StaProcurement < Staging::StagingRecord
    set_table_name "sta_procurements"
    
    validates_uniqueness_of :supplier_ico, :scope => [:document_id, :price]
  end
end
