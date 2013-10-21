# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class LawyerAssociateExtraction
    attr_reader :url, :reset_url, :parent_url

    def initialize(url, reset_url = nil, cookie = nil, parent_url = nil, filter = nil)
      @url, @reset_url, @cookie, @parent_url, @filter = url, reset_url, cookie, parent_url, filter
    end

    def download
      if @parent_url.present? && @cookie.present? && @reset_url
        Typhoeus::Request.get(@reset_url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true)
        Typhoeus::Request.get(@parent_url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true)
      end
      Nokogiri::HTML( Typhoeus::Request.get(@url, headers: {'Cookie' => @cookie}, disable_ssl_peer_verification: true).body )
    end

    def is_acceptable?(document)
      document.xpath("//div[@class='section']/table[@class='filter']").present?
    end

    def perform
      document = download
      if is_acceptable?(document)
        lawyer_partnership_hash = digest(document)
        save(lawyer_partnership_hash)
      end
    end

    def digest(doc)
      lawyer_associate_table = doc.xpath("//div[@class='section']/table[@class='filter']").first
      original_name = lawyer_associate_table.xpath('./tr[1]/td[2]').inner_text.strip

      employer_name = lawyer_associate_table.xpath('./tr[2]/td[2]').inner_text.strip
      ds_lawyers = []
      ds_lawyer_partnerships = []

      if ds_lawyer_partnership = Kernel::DsLawyerPartnership.find_by_name(employer_name)
        ds_lawyer_partnerships << ds_lawyer_partnership
      elsif ds_lawyer = Kernel::DsLawyer.find_by_original_name(employer_name)
        ds_lawyers << ds_lawyer
      end

      sak_id = (@url.match(/\d+/)[0].to_i rescue nil)
      match_data = original_name.match(/(?<last_name>[^\s]+)\s+(?<first_name>[^\s]+)(\s+(?<title>[^\s]+))*/)
      {
        original_name: original_name,
        first_name: match_data[:first_name],
        last_name: match_data[:last_name],
        title: match_data[:title],
        ds_lawyers: ds_lawyers,
        ds_lawyer_partnerships: ds_lawyer_partnerships,
        sak_id: sak_id,
        is_part_of_import: true
      }
    end

    def save(lawyer_associate_hash)
      lawyer_associate = Dataset::DsLawyerAssociate.find_or_initialize_by_sak_id(lawyer_associate_hash[:sak_id])
      lawyer_associate.update_attributes!(lawyer_associate_hash)
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

    def parse_for_links(doc, reset_url, cookie, parent_url, filter)
      doc.xpath("//div[@class='result']/table//a").map do |link|
        Etl::LawyerAssociateExtraction.new("https://www.sak.sk/#{link.attributes['href'].value.match(/'(.*)'/)[1]}", reset_url, cookie, parent_url, filter)
      end
    end

  end
end
