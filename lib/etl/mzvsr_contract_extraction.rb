# encoding: utf-8

class Etl::MzvsrContractExtraction
  attr_reader   :uri, :content, :attributes
  attr_accessor :parser, :downloader

  def initialize(uri)
    @uri    = uri
    @parser = Parser
  end

  def download
    @content ||= Typhoeus::Request.get(uri).body
  end

  def parse
    @attributes ||= parser.parse(content).merge(uri: uri)
  end

  def save
    contract = Dataset::DsMzvsrContract.find_or_initialize_by_uri(attributes[:uri])

    contract.update_attributes!(attributes)
  end

  def perform
    download
    parse
    save
  end

  class Parser
    def self.parse(html)
      result   = Hash.new
      document = Nokogiri::HTML(html)

      tables = document.css('#mainContent table.ksSectionContext')

      result[:title_sk] = tables[0].css('tr')[0].css('td').text.strip
      result[:title_en] = tables[0].css('tr')[1].css('td').text.strip.presence
      result[:country]  = tables[1].css('tr')[0].css('td').text.strip.presence
      result[:place]    = tables[1].css('tr')[1].css('td').text.strip.presence
      result[:signed_on] = Date.parse(tables[1].css('tr')[2].css('td').text) rescue nil
      result[:valid_from] = Date.parse(tables[1].css('tr')[3].css('td').text) rescue nil
      result[:law_index] = tables[1].css('tr')[4].css('td').text.strip.presence.first(255)
      result[:type] = tables[1].css('tr')[5].css('td').text.strip.gsub(/-/, '').presence
      result[:administrator] = tables[1].css('tr')[7].css('td').text.strip.presence
      result[:protocol_number] = tables[1].css('tr')[8].css('td').text.strip.presence
      result[:priority] = case tables[1].css('tr')[6].css('td').text.strip
                          when 'Áno' then true
                          when 'Nie' then false
                          else nil
                          end
      result
    end
  end
end
