# -*- encoding : utf-8 -*-
class SystemVariable < ActiveRecord::Base
  translates :description
  locale_accessor :sk, :en
  
  def self.get(name, default = nil)
    @variables_cache ||= self.all
    begin
      variable = @variables_cache.detect { |variable| variable.name == name.to_s }
    rescue
      variable = find_by_name(name)
      @variables_cache = self.all
    end
    value = variable ? variable.value : default
    value = false if value == "0"
    value
  end
end
