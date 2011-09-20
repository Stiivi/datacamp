# -*- encoding : utf-8 -*-
module Staging
  class StaNotar < Staging::StagingRecord
    set_table_name "sta_notaries"
    
    validates_uniqueness_of :doc_id
    
    def self.active
      where(active: true)
    end
  end
end
