# -*- encoding : utf-8 -*-
class SearchExtractor

  def self.extract
    CSV.open("data/searches_#{Date.today.strftime('%Y_%m_%d')}.csv", "wb") do |csv|
      csv << ['ID', 'created at', 'query', 'type', 'scope', 'object']
      Search.find_each do |search|
        csv << [search.id, search.created_at.strftime('%Y-%m-%d %H:%M'), search.query_string,
                search.search_type, search.query.scope, search.query.object]
      end
    end
  end

end
