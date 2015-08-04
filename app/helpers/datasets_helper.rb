# -*- encoding : utf-8 -*-
module DatasetsHelper

  def sort_link(field)
    params[:dir] ||= "asc"
    lab = html_escape(field.title).html_safe
    lab += image_tag "sort_#{params["dir"]}.png" if params[:sort] == field.identifier

    href = {:page => params[:page], :search_id => params[:search_id]}
    href[:sort] = field.identifier

    if field.identifier == params[:sort]
      href[:dir] = params[:dir] == "asc" ? "desc" : "asc"
    else
      href[:dir] = "asc"
    end

    link = link_to(lab, href, name: "Click to sort by #{field.title}", class: 'js_sort_link', data: {tracking_field_id: field.identifier, tracking_direction: href[:dir]})
    link
  end

end
