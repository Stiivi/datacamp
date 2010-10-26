module MainHelper
  def link_to_page(name, label = nil)
    page = Page.find_by_page_name(name)
    if page
      link_to(label || page.title, page)
    end
  end
end
