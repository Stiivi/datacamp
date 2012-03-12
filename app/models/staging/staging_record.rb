# -*- encoding : utf-8 -*-
module Staging
  class StagingRecord < ActiveRecord::Base
    establish_connection Rails.env + "_staging"
  end
end
