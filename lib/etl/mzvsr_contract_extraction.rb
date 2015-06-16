# encoding: utf-8
require 'etl/page_loader'

class Etl::MzvsrContractExtraction
  attr_reader :uri, :attributes, :page_loader, :page_class

  def initialize(uri, params = {})
    @uri    = uri
    @page_loader = params.fetch(:page_loader) { Etl::PageLoader }
    @page_class = params.fetch(:page_class) { Etl::MzvsrContractExtraction::ContractPage }
  end

  def parse
    @attributes ||= page.information.merge(uri: uri, record_status: 'published')
  end

  def save
    contract = Dataset::DsMzvsrContract.find_or_initialize_by_uri(attributes[:uri])

    contract.update_attributes!(attributes)
  end

  def perform
    parse
    save
  end

  def page
    @page ||= page_loader.load_by_get(uri, page_class)
  end

  class ContractPage
    attr_reader :document

    def initialize(document, params = {})
      @document = document
    end

    def information
      result   = Hash.new

      tables = document.css('#mainContent table.ksSectionContext')

      result[:title_sk] = tables[0].css('tr')[0].css('td').text.strip
      result[:title_en] = tables[0].css('tr')[1].css('td').text.strip.presence
      result[:country]  = tables[1].css('tr')[0].css('td').text.strip.presence
      result[:place]    = tables[1].css('tr')[1].css('td').text.strip.presence
      result[:signed_on] = Date.parse(tables[1].css('tr')[2].css('td').text) rescue nil
      result[:valid_from] = Date.parse(tables[1].css('tr')[3].css('td').text) rescue nil
      law_index = tables[1].css('tr')[4].css('td').text.strip.presence
      law_index = law_index.first(255) if law_index
      result[:law_index] = law_index
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
