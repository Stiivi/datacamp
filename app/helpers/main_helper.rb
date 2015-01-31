# -*- encoding : utf-8 -*-
module MainHelper
  def link_to_page(name, label = nil)
    if @pages
      page = @pages.select{|p| p.page_name == name}.first
    else
      page = Page.find_by_page_name(name)
    end
    if page
      link_to(label || page.title, page)
    end
  end
end
