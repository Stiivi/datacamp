# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class FoundationPageExtraction < Etl::PageExtraction

    def document_url
      "http://www.ives.sk/registre/zoznamrnd.do?action=azzu&cisloStrany=#{page_number}&locale=sk"
    end

    def is_acceptable?
      document.xpath("//div[@class='divForm']//table[@class='zoznam']").present?
    end

    def get_downloads
      downloads = []
      document.xpath("//div[@class='divForm']//table[@class='zoznam']//tr")[1..-1].each do |row|
        ives_id = row.xpath(".//td[2]//a").first.attributes["href"].value.scan(/(.*)id=(.*)/).first.last.to_i
        downloads << ives_id if ives_id
      end
      downloads
    end

    def perform
      if is_acceptable?
        get_downloads.each do |ives_id|
          Delayed::Job.enqueue Etl::FoundationExtraction.new(ives_id)
        end
      end
    end

  end
end
