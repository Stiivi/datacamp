# -*- encoding : utf-8 -*-
module Staging
  class StaTrainee < Staging::StagingRecord
    set_table_name "sta_trainees"
    belongs_to :advokat, :class_name => "Staging::StaAdvokat", :foreign_key => :advokat_id
  end
end
