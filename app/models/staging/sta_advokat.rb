# -*- encoding : utf-8 -*-
module Staging
  class StaAdvokat < Staging::StagingRecord
    set_table_name "sta_advokats"
    
    # validates_uniqueness_of :name, :scope => [:doc_id, :worker_name]
  end
end
