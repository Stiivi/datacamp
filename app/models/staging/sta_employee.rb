module Staging
  class StaEmployee < Staging::StagingRecord
    belongs_to :sta_notar, :class_name => "Staging::StaNotar"
    self.table_name = 'sta_employees'
  end
end
