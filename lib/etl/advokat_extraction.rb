# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class AdvokatExtraction
    
    def initialize(url, reset_url = nil, cookie = nil, parent_url = nil)
      @url, @reset_url, @cookie, @parent_url = url, reset_url, cookie, parent_url
    end
    
    def is_acceptable?(document)
      document.xpath("//div[@class='section']/table[@class='filter']").present?
    end
    
    def download
      if @parent_url.present? && @cookie.present? && @reset_url
        Typhoeus::Request.get(@reset_url, :headers => {'Cookie' => @cookie})
        Typhoeus::Request.get(@parent_url, :headers => {'Cookie' => @cookie})
      end
      Nokogiri::HTML( Typhoeus::Request.get(@url, :headers => {'Cookie' => @cookie}).body )
    end
    
    def digest(doc)
      advokat_table = doc.xpath("//div[@class='section']/table[@class='filter']").first
      
      trainees = doc.xpath("//div[@id='blox/cms/sk/sak/adv/vyhladanie/proxy/link/display/formular/attr/cms/section/proxyKoncipient']/div/div/table/tr")
      trainees_attributes = trainees.map do |trainee|
        next if trainee.xpath("./th").present? || trainee.inner_text.match(/Zoznam je prázdny/).present?
        tr = trainee.xpath("./td[2]").first.inner_text.strip
        match_data = tr.match(/(?<first_name>[^\s]+)\s+(?<last_name>[^\s]+)\s+(?<title>[^\s]+)/)
        ({first_name: match_data[:first_name], last_name: match_data[:last_name], title: match_data[:title]} rescue nil)
      end.compact
      
      {
        :name => advokat_table.xpath('./tr[1]/td[2]').inner_text.strip,
        :avokat_type => advokat_table.xpath('./tr[2]/td[2]').inner_text.strip,
        :street => advokat_table.xpath('./tr[3]/td[2]').inner_text.strip,
        :city => advokat_table.xpath('./tr[4]/td[2]').inner_text.strip,
        :zip => advokat_table.xpath('./tr[5]/td[2]').inner_text.strip,
        :phone => advokat_table.xpath('./tr[6]/td[2]').inner_text.strip,
        :fax => advokat_table.xpath('./tr[7]/td[2]').inner_text.strip,
        :cell_phone => advokat_table.xpath('./tr[8]/td[2]').inner_text.strip,
        :languages => advokat_table.xpath('./tr[9]/td[2]').inner_text.strip,
        :email => advokat_table.xpath('./tr[10]/td[2]').inner_text.strip,
        :website => (advokat_table.xpath('./tr[11]/td[2]/a').first.attributes['href'].value rescue nil),
        :url => @url,
        :ds_trainees_attributes => trainees_attributes
      }
    end
    
    def perform
      document = download
      if is_acceptable?(document)
        advokat_hash = digest(document)
        save(advokat_hash)
      end
    end
    
    def save(advokat_hash)
      Dataset::DsAdvokat.create(advokat_hash)
    end
    
    def get_downloads
      id = 0
      downloads = []
      begin
        doc_data = Typhoeus::Request.get(@url + id.to_s)
        cookie = doc_data.headers_hash['Set-Cookie'].match(/[^ ;]*/)[0]
        doc = Nokogiri::HTML( doc_data.body )
        downloads << parse_for_links(doc, @reset_url, cookie, @url + id.to_s)
        id += 10
      end while doc.xpath("//div[@class='buttonbar']/table//tr[1]//td[@style='opacity: 0.5']").inner_html.match(/but_arrow_right.gif/).blank?
      downloads.flatten
    end
    
    def parse_for_links(doc, reset_url, cookie, parent_url)
      doc.xpath("//div[@class='result']/table//a").map do |link|
        Etl::AdvokatExtraction.new("https://www.sak.sk/#{link.attributes['href'].value.match(/'(.*)'/)[1]}", reset_url, cookie, parent_url)
      end
    end
    
  end
end