module Api
  RESTRICTED = 0
  REGULAR = 1
  PREMIUM = 2
  
  class << self
    def access_levels
      { :restricted => 0,
        :regular => 1,
        :premium => 2 }
    end
  end
  
  module Accessable
    def api_level
      api_access_level || 0
    end
  end
end