# -*- encoding : utf-8 -*-
module Staging
  class StaExecutor < Staging::StagingRecord
    self.table_name = 'sta_executors'
    
    # validates_uniqueness_of :name, :scope => [:doc_id, :worker_name]
  end
end
