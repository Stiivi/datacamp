# -*- encoding : utf-8 -*-
module ApplicationHelper
  def button_link_to(what, where, *options)
    options = options.extract_options!
    klass = options[:class] ? options[:class] + " button" : "button"
    options[:class] = klass
    what = "<span>%s</span>" % what
    link_to what.html_safe, where, options
  end
  
  def has_privilege?(priv)
    logged_in? && current_user.has_privilege?(priv)
  end
  
  def add_translations_to_array(array, key = "global")
    array.map{|item|[t("#{key}.#{item}"), item]}
  end
  
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    
    fields = f.fields_for association, new_object, :child_index => "new_#{association}" do |builder|
      render(partial: association.to_s.singularize + "_fields", locals: {f: builder, index: 0})
    end
    f.submit name, :name => "add_#{association.to_s.singularize}", :class => 'add_element', 'data-element' => "#{fields}", 'data-association' => association
  end

  def textile(text)
    RedCloth.new(text || '').to_html.html_safe
  end

  def clear_textile(text)
    strip_tags(RedCloth.new(text || '').to_html)
  end
end
