# -*- encoding : utf-8 -*-
module Staging
  class StaNotar < Staging::StagingRecord
    set_table_name "sta_notaries"
    has_many :sta_employees, :class_name => "Staging::StaEmployee"
    accepts_nested_attributes_for :sta_employees
    
    validates_uniqueness_of :doc_id
    
    def self.active
      where(active: true)
    end
  end
end
