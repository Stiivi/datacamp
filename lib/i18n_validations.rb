# -*- encoding : utf-8 -*-
module I18nValidations
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    def validates_presence_of_i18n *attr_names
      options = { :on => :save, :locales => [:en], :message => I18n.t("activerecord.errors.messages.blank_i18n") }
      options.update(attr_names.extract_options!)
      
      attr_names.each do |attr|
        options[:locales].each do |locale|
          validates_presence_of "#{locale}_#{attr}"
        end
      end
    end
    
  end
  
end
