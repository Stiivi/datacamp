class StagingRecord < ActiveRecord::Base
  
  establish_connection RAILS_ENV + "_staging"
  
end