module DatasetsHelper
  
  def sort_link(field)
    params[:dir] ||= "asc"
    lab = field.title
    lab += image_tag "sort_#{params["dir"]}.png" if params[:sort] == field.identifier
    
    href = {:page => params[:page]}
    href[:sort] = field.identifier
    
    if field.identifier == params[:sort]
      href[:dir] = params[:dir] == "asc" ? "desc" : "asc"
    else
      href[:dir] = "asc"
    end
    
    link = link_to(lab, href, :name => "Click to sort by #{field.title}")
    link
  end
  
end