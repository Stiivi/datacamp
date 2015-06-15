module Etl
  class PageLoader
    def self.load_by_get(url, page_class)
      page_class.new(Nokogiri::HTML(Typhoeus::Request.get(url).body))
    end
  end
end
