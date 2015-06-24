# -*- encoding : utf-8 -*-
module Staging
  class StagingRecord < ActiveRecord::Base
    establish_connection Rails.env + "_staging"

    self.abstract_class = true
  end
end
