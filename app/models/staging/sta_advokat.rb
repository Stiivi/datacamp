# -*- encoding : utf-8 -*-
module Staging
  class StaAdvokat < Staging::StagingRecord
    set_table_name "sta_advokats"
    
    has_many :trainees, :class_name => "Staging::StaTrainee", :foreign_key => :advokat_id
    accepts_nested_attributes_for :trainees
    
    validates_uniqueness_of :url
  end
end
