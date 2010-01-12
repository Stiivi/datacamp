module MainHelper
  def link_to_page(name)
    page = Page.find_by_page_name(name)
    if page
      link_to page.title, page
    end
  end
end
