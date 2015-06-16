require 'etl/page_loader'
module Etl
  class MzvsrContractsPageExtraction
    attr_reader :page_number, :page_loader, :page_class

    def initialize(page_number=1, params = {})
      @page_number = page_number
      @page_loader = params.fetch(:page_loader) { Etl::PageLoader }
      @page_class = params.fetch(:page_class) { Etl::MzvsrContractsPageExtraction::ContractListingPage }
    end

    def base_url
      'http://www.mzv.sk'
    end

    def document_url
      "#{base_url}/servlet/content?MT=/App/WCM/main.nsf/vw_ByID/zahranicna__politika&TG=BlankMaster&URL=/App/WCM/main.nsf/vw_ByID/medzinarodne_zmluvy-vsetky_zmluvy&OpenDocument=Y&LANG=SK&PAGE_MEDZINARODNEZMLUVY-ALL-DWMCEA-7XRF9N=#{page_number}"
    end

    def is_acceptable?
      return true if page.acceptable?

      Etl::MzvsrContractsPageExtraction.new(page_number + 1).page.acceptable?
    end

    def page
      @page ||= page_loader.load_by_get(document_url, page_class, base_url: base_url)
    end

    def perform
      if is_acceptable?
        page.detail_urls.each do |uri|
          Delayed::Job.enqueue(self.class.new(uri))
        end
      end
    end

    def after(job)
      if is_acceptable?
        Delayed::Job.enqueue self.class.new(page_number+1)
      end
    end

    class ContractListingPage
      attr_reader :document, :base_url

      def initialize(document, params = {})
        @document = document
        @base_url = params.fetch(:base_url)
      end

      def detail_urls
        document.css('#newsWrapperMain .tableRT2 tr td a[title]').map do |link|
          "#{base_url}#{link['href']}"
        end
      end

      def acceptable?
        document.css('#newsWrapperMain .tableRT2 tr td a').present?
      end
    end
  end
end
