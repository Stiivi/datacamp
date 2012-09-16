# -*- encoding : utf-8 -*-
module I18nHelper
  def locale_switcher form, *locales
    prefix = dom_id(form.object)
    buttons = ''.html_safe
    locales.flatten.each do |locale|
      buttons << content_tag(:li, content_tag(:a, locale.to_s.upcase, :href => '#'+ prefix + "_" + locale.to_s), :class => I18n.locale.to_s == locale.to_s ? "active" : "").html_safe
    end
    content_tag(:ul, buttons, :class => 'locale_switcher tabs small clearfix')
  end
  
  def locale_tabs form, *locales, &block
    fields = ''.html_safe
    locales.flatten.each do |locale|
      fields << content_tag(:ul, capture(I18nFormBuilder.new(locale, form), &block), id: dom_id(form.object) + "_" + locale.to_s)
    end
    content_tag(:li, content_tag(:div, fields, :class => 'tabs'))
  end
end
