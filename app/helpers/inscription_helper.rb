# -*- encoding : utf-8 -*-
##################################################
# Requires frontend code from inscription.js

module InscriptionHelper
  def modal(*args)
    @options = args.extract_options!
    
    @options[:size] ||= "small"
    @options[:position] ||= "center"
    
    if @options[:partial]
      @options[:html] = render :partial => @options[:partial]
      @options.delete(:partial)
    end
    
    "$.modal(#{@options.to_json})".html_safe;
  end
end
