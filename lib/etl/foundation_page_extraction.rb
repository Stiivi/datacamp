# -*- encoding : utf-8 -*-
require 'etl/page_loader'

module Etl
  class FoundationPageExtraction
    attr_reader :page_number, :document_url, :page_loader, :page_class

    def initialize(page_number=1, params = {})
      @page_number = page_number
      @document_url = params.fetch(:url) { "http://www.ives.sk/registre/zoznamrnd.do?action=azzu&cisloStrany=#{page_number}&locale=sk" }
      @page_loader = params.fetch(:page_loader) { Etl::PageLoader }
      @page_class = params.fetch(:page_class) { Etl::FoundationPageExtraction::FoundationListingPage }
    end

    def perform
      page.foundation_ids.each do |ives_id|
        Delayed::Job.enqueue Etl::FoundationExtraction.new(ives_id)
      end
    end

    def after(job)
      if page.foundation_ids.count > 0
        Delayed::Job.enqueue self.class.new(page_number+1)
      end
    end

    def page
      @page ||= page_loader.load_by_get(document_url, page_class)
    end

    class FoundationListingPage
      attr_reader :document, :params

      def initialize(document, params = {})
        @document = document
        @params = params
      end

      def foundation_ids
        return [] unless acceptable?

        @foundation_ids ||= begin
          ids = []
          document.xpath("//div[@class='divForm']//table[@class='zoznam']//tr")[1..-1].each do |row|
            ives_id = row.xpath(".//td[2]//a").first.attributes["href"].value.scan(/(.*)id=(.*)/).first.last.to_i
            ids << ives_id if ives_id
          end
          ids
        end
      end

      private

      def acceptable?
        document.xpath("//div[@class='divForm']//table[@class='zoznam']").present?
      end
    end
  end
end
