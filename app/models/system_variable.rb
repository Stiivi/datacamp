# -*- encoding : utf-8 -*-
class SystemVariable < ActiveRecord::Base
  translates :description
  locale_accessor :sk, :en

  # TODO move to config
  def self.get(name, default = nil)
    @variables_cache ||= self.all
    begin
      variable = @variables_cache.detect { |variable| variable.name == name.to_s }
    rescue
      begin
        variable = self.find_by_name(name)
        @variables_cache = self.all
      end
    end
    value = variable ? variable.value : default
    value = false if value == "0"
    value
  end

  def self.reload_variables
    @variables_cache = nil
  end
end
