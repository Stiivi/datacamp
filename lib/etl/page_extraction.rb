# -*- encoding : utf-8 -*-

module Etl
  class PageExtraction

    attr_reader :page_number

    def initialize(page_number=1)
      @page_number = page_number
    end

    def download
      Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
    end

    def document
      @document ||= download
    end

    def document_url
      # implement
    end

    # return true if documen is acceptable for perform
    def is_acceptable?
      # implement
    end

    def perform
      # implement
    end

    def after(job)
      if is_acceptable?
        Delayed::Job.enqueue self.class.new(page_number+1)
      end
    end

  end
end
