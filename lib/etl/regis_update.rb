# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class RegisUpdate < Struct.new(:start_id, :batch_limit, :id)
    def perform
      puts "downloading: #{id}"
      document = download(id)
      puts "parsing: #{id}"
      procurement_hash = parse(id, document)
      unless procurement_hash == :unknown_announcement_type
        puts "saving: #{id}"
        save(procurement_hash, id)
        update_last_processed(id)
      end
    end

    def download(id)
      Typhoeus::Request.get(document_url(id))
    end

    def update_last_processed(id)
      config.update_attribute(:last_processed_id, id)
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('regis_update')
    end

    def document_url(id)
      "http://www.statistics.sk/pls/wregis/detail?wxidorg=#{id}"
    end

    def save(procurement_hash, document_id)
      regis_model = Kernel.const_get 'StagingRecord'
      regis_model.set_table_name "sta_regis_main"
      modified_element = regis_model.find_by_doc_id(document_id)
      modified_element.update_attributes(procurement_hash)
    end

    def parse(id, document)
        file_content = Iconv.conv('utf-8', 'cp1250', document.body).gsub("&nbsp;",' ')
        doc = Nokogiri::HTML(file_content)

        return :unknown_announcement_type if doc.xpath("//div[@class='telo']").empty?
        return digest(doc, id, document_url(id))
    end

    def digest(doc, doc_id, base_url, url = nil)
      ico = name = legal_form = date_start = date_end = address = region = ''
      doc.xpath("//div[@class='telo']//table[@class='tabid']/tbody/tr").each do |row|
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
      doc.xpath("//div[@class='telo']//table[@class='tablist']/tbody/tr").each do |row|
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

      url ||= base_url.to_s

      { :doc_id => doc_id,
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

    def after(job)
      if id == (start_id + batch_limit) && !config.last_processed_id > start_id
          config.update_attribute(:start_id, id+1)
      end
    end
  end
end
