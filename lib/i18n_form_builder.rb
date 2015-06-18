# -*- encoding : utf-8 -*-
class I18nFormBuilder
  
  def initialize(locale, form)
    @form = form
    @locale = locale
  end
  
  def method_missing(method, field, *args)
    # TODO do this only if we're playing with text_field, text_area, etc. - form helpers
    # otherwise DIE!
    field = (@locale.to_s + "_" + field.to_s).to_sym
    @form.send(method, field, *args)
  end

end
