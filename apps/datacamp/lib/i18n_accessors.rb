module I18nAccessors
  def self.included(base)
    base.extend ActMethods
  end
  
  module ActMethods      
    def locale_accessor *locales
      raise RuntimeError, "Globalize is not initialized with this model, can't summon accessors." unless globalize_options
      
      locales.flatten!
      
      # Methods for each locale individualy
      locales.each do |locale|
        locale = locale.to_s
        
        # Get translation object        
        define_method locale do
          globalize_translations.find :first, :conditions => {:locale => locale}
        end
        
        # Set translation object
        define_method "#{locale}=" do |attrs|
          set_translations locale.to_sym => attrs
        end
      end
      
      translated_attributes = globalize_options[:translated_attributes]
      
      translated_attributes.each do |attribute|
        locales.each do |locale|
          # Getter
          define_method "#{locale}_#{attribute}" do
            return globalize.fetch(locale, attribute)
          end
          # Setter
          define_method "#{locale}_#{attribute}=" do |value|
            return globalize.stash(locale, attribute, value)
          end
        end
      end
      
    end
  end
end