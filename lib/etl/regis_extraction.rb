# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class RegisExtraction < Etl::Extraction
    def document_url(id)
      "http://www.statistics.sk/pls/wregis/detail?wxidorg=#{id}"
    end

    def is_acceptable?(document)
      document.xpath("//div[@class='telo']").present?
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('regis_extraction')
    end

    def digest(doc)
      ico = name = legal_form = date_start = date_end = address = region = ''
      doc.xpath("//table[@class='tabid']/tbody/tr").each do |row|
        if row.xpath(".//td[1]").inner_text.match(/i(Č|č|c)o/i)
          ico = row.xpath(".//td[3]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/meno/i)
          name = row.xpath(".//td[3]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/forma/i)
          legal_form = row.xpath(".//td[3]").inner_text.split('-')[0].strip
        elsif row.xpath(".//td[1]").inner_text.match(/vzniku/i)
          date_start = row.xpath(".//td[3]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/z(a|á|Á)niku/i)
          date_end = row.xpath(".//td[3]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/adresa/i)
          address = row.xpath(".//td[3]").inner_text.strip
        elsif row.xpath(".//td[1]").inner_text.match(/okres/i)
          region = row.xpath(".//td[3]").inner_text.strip
        end
      end

      activity1 = activity2 = account_sector = ownership = size = ''
      doc.xpath("//table[@class='tablist']/tbody/tr").each do |row|
        if row.xpath(".//td[1]").inner_text.match(/SK NACE/i)
          activity1 = row.xpath(".//td[2]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/OKE(Č|č|c)/i)
          activity2 = row.xpath(".//td[2]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/sektor/i)
          account_sector = row.xpath(".//td[2]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/vlastn(i|í|Í)ctva/i)
          ownership = row.xpath(".//td[2]").inner_text
        elsif row.xpath(".//td[1]").inner_text.match(/ve(l|ľ|Ľ)kosti/i)
          size = row.xpath(".//td[2]").inner_text
        end
      end

      date_start = Date.parse(date_start) rescue nil
      date_end = Date.parse(date_end) rescue nil

      url = document_url(id).to_s

      { :doc_id => id,
        :ico => ico,
        :name => name,
        :legal_form => legal_form,
        :date_start => date_start,
        :date_end => date_end,
        :address => address,
        :region => region,
        :activity1 => activity1,
        :activity2 => activity2,
        :account_sector => account_sector,
        :ownership => ownership,
        :size => size,
        :date_created => Time.now,
        :source_url => url }
    end

    def save(procurement_hash)
      Staging::StaRegisMain.create(procurement_hash)
    end

    def enque_job(document_id)
      Delayed::Job.enqueue Etl::RegisExtraction.new(id+1, config.batch_limit, document_id)
    end

  end
end
