# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def button_link_to(what, where, *options)
    options = options.extract_options!
    klass = options[:class] ? options[:class] + " button" : "button"
    options[:class] = klass
    what = "<span>%s</span>" % what
    link_to what, where, options
  end
  
  def has_privilege?(priv)
    logged_in? && current_user.has_privilege?(priv)
  end
  
  def add_translations_to_array(array, key = "global")
    array.map{|item|[t("#{key}.#{item}"), item]}
  end
end