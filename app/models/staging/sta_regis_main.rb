# -*- encoding : utf-8 -*-
module Staging
  class StaRegisMain < Staging::StagingRecord
    set_table_name "sta_regis_main"

    validates_uniqueness_of :doc_id

    serialize :name_history, Hash
  end
end
