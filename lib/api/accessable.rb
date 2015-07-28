# -*- encoding : utf-8 -*-
module Api
  RESTRICTED = 0
  REGULAR = 1
  PREMIUM = 2

  module Accessable
    def api_level
      api_access_level || 0
    end

    def api_allowed?
      return self.api_level > RESTRICTED
    end
    
    def api_allowed_for?(other_accessable)
      return false unless other_accessable
      self.api_level > RESTRICTED &&
      self.api_level <= other_accessable.api_level
    end
  end
  
  class << self
    def access_levels
      { :restricted => 0,
        :regular => 1,
        :premium => 2 }
    end
  end
  
end
