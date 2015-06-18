# -*- encoding : utf-8 -*-
class SphinxSearchEngine
  def create_search_with_string(string)
    search = Search.new
    search.query_string = string
    search.search_type = "text"

    query = SearchQuery.query_with_string(string, :scope=>'global', :object=>nil)
    search.query = query
    query.save
    search.save
    search
  end
end
