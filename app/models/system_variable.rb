class SystemVariable < ActiveRecord::Base
  translates :description
  locale_accessor :sk, :en
  
  def self.get(name, default = "")
    variable = find_by_name(name)
    variable ? variable.value : default
  end
end
