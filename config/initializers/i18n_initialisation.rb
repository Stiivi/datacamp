# -*- encoding : utf-8 -*-
ActiveRecord::Base.module_eval do
  include I18nAccessors
  include I18nValidations
end
