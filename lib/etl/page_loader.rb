module Etl
  class PageLoader
    def self.load_by_get(url, page_class, params = {})
      page_class.new(Nokogiri::HTML(Typhoeus::Request.get(url).body), params)
    end
  end
end
