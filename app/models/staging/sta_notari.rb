# -*- encoding : utf-8 -*-
module Staging
  class StaNotari < Staging::StagingRecord
    set_table_name "sta_notaries"
    
    validates_uniqueness_of :name, :scope => [:doc_id, :worker_name]
  end
end
