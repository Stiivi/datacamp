# -*- encoding : utf-8 -*-
class StagingRecord < ActiveRecord::Base
  
  establish_connection Rails.env + "_staging"
  
end
