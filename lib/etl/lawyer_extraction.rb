# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class LawyerExtraction
    attr_reader :url, :parent_url, :reset_url

    def initialize(url, reset_url = nil, cookie = nil, parent_url = nil, filter = nil)
      @url, @reset_url, @cookie, @parent_url, @filter = url, reset_url, cookie, parent_url, filter
    end

    def self.update_last_run_time
      EtlConfiguration.find_by_name('lawyer_extraction').update_attribute(:last_run_time, Time.now)
    end

    def is_acceptable?(document)
      document.xpath("//div[@class='section']/table[@class='filter']").present?
    end

    def download
      if @parent_url.present? && @cookie.present? && @reset_url
        Typhoeus::Request.get(@reset_url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true)
        Typhoeus::Request.get(@parent_url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true)
      end
      Nokogiri::HTML( Typhoeus::Request.get(@url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true).body )
    end

    def digest(doc)
      lawyer_table = doc.xpath("//div[@class='section']/table[@class='filter']").first

      original_name = lawyer_table.xpath('./tr[1]/td[2]').inner_text.strip
      name_ary = original_name.split
      match_data = {last_name: [], first_name: [], middle_name: [], title: []}
      name_ary.each_with_index do |name_part, index|
        if (index+1 != name_ary.length) && (name_part.match(/[A-ZŘÁÉÍÓÚÝČĎĽŇŠŤŽÔÄů]+(?=\s|\z)/) || name_part.match(/(ova|ová|ska|ská)(?=\s|\z)/))
          match_data[:last_name] << name_part.mb_chars.titleize
        elsif match_data[:first_name].blank?
          match_data[:first_name] << name_part
        elsif mat = name_part.match(/(?<title>dr\.jur\.|^et$|DDr|Doc|JUD(r|R)|CSc|Ph\.D|PhD|D\.Phil|DPhil|Dott|Dr|LL\.M|Ing|Mgr|JCLic|Bc|Ph\.D|MBA|MPH|MVDr|Prof|RNDr|DiS|Dott|^ssa$|DrSc|M\.E\.S|MBLT|MUDr|PaedDr|Mag|BA|(p|P)rom\.|(p|P)ráv\.|M\.A\.|(i|I)(u|U)(r|R)\.)(\.?)/)
          match_data[:title] << name_part if mat[:title].present?
        elsif !name_part.match(/(st|ml)\.|\./)
          match_data[:middle_name] << name_part
        end
      end

      sak_id = (@url.match(/\d+/)[0].to_i rescue nil)
      {
        :original_name => original_name,
        first_name: match_data[:first_name].join(' '),
        last_name: match_data[:last_name].join(' '),
        middle_name: match_data[:middle_name].present? ? match_data[:middle_name].join(' ') : nil,
        title: match_data[:title].join(' '),
        :lawyer_type => lawyer_table.xpath('./tr[2]/td[2]').inner_text.strip,
        :street => lawyer_table.xpath('./tr[3]/td[2]').inner_text.strip,
        :city => (lawyer_table.xpath('./tr[4]/td[2]').inner_text.strip.mb_chars.upcase.to_s rescue nil),
        :zip => lawyer_table.xpath('./tr[5]/td[2]').inner_text.gsub(/\s+/, '').strip,
        :phone => lawyer_table.xpath('./tr[6]/td[2]').inner_text.strip,
        :fax => lawyer_table.xpath('./tr[7]/td[2]').inner_text.strip,
        :cell_phone => lawyer_table.xpath('./tr[8]/td[2]').inner_text.strip,
        :languages => lawyer_table.xpath('./tr[9]/td[2]').inner_text.strip,
        :email => lawyer_table.xpath('./tr[10]/td[2]').inner_text.strip,
        :website => (validate_url(lawyer_table.xpath('./tr[11]/td[2]/a').first.attributes['href'].value) rescue nil),
        :url => @url,
        :sak_id => sak_id,
        :is_part_of_import => true
      }
    end

    def validate_url(url)
      parsed_url = URI.parse(url)
      if parsed_url.class == URI::HTTP
        url
      else
        nil
      end
    end

    def perform
      document = download
      if is_acceptable?(document)
        lawyer_hash = digest(document)
        save(lawyer_hash)
      end
    end

    def save(lawyer_hash)
      lawyer = Kernel::DsLawyer.find_or_initialize_by_sak_id(lawyer_hash[:sak_id])
      lawyer.update_attributes!(lawyer_hash)
    end

    def get_downloads
      id = 0
      downloads = []
      begin
        doc_data = Typhoeus::Request.get(@url + id.to_s, disable_ssl_peer_verification: true)
        cookie = doc_data.headers_hash['Set-Cookie'].match(/[^ ;]*/)[0]
        doc = Nokogiri::HTML( doc_data.body )
        downloads << parse_for_links(doc, @reset_url, cookie, @url + id.to_s, @filter)
        id += 10
      end while doc.xpath("//div[@class='buttonbar']/table//tr[1]//td[@style='opacity: 0.5']").inner_html.match(/but_arrow_right.gif/).blank?
      downloads.flatten
    end

    def parse_id
      url.match(/\d+/)[0].to_i rescue nil
    end

    def self.map_ids(downloads)
      downloads.map{ |d| d.parse_id }
    end

    def get_ids_from_downloads
       Etl::LawyerExtraction.map_ids(get_downloads)
    end

    def parse_for_links(doc, reset_url, cookie, parent_url, filter)
      doc.xpath("//div[@class='result']/table//a").map do |link|
        Etl::LawyerExtraction.new("https://www.sak.sk/#{link.attributes['href'].value.match(/'(.*)'/)[1]}", reset_url, cookie, parent_url, filter)
      end
    end

  end
end
