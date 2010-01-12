module I18nHelper
  def locale_switcher form, *locales
    prefix = dom_id(form.object)
    buttons = []
    locales.flatten.each do |locale|
      buttons << content_tag(:li, content_tag(:a, locale.to_s.upcase, :href => '#'+ prefix + "_" + locale.to_s), :class => I18n.locale.to_s == locale.to_s ? "active" : "")
    end
    content_tag(:ul, buttons, :class => 'locale_switcher tabs small clearfix')
  end
  
  def locale_tabs form, *locales
    puts '<li><div class="tabs">'
      locales.flatten.each do |locale|
        puts sprintf('<div id="%s">', dom_id(form.object) + "_" + locale.to_s)
          yield I18nFormBuilder.new(locale, form)
        puts '</div>'
      end
    puts '</div></li>'
  end
end