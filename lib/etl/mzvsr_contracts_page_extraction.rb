module Etl
  class MzvsrContractsPageExtraction < Etl::PageExtraction
    def base_url
      'http://www.mzv.sk'
    end

    def document_url
      "#{base_url}/servlet/content?MT=/App/WCM/main.nsf/vw_ByID/zahranicna__politika&TG=BlankMaster&URL=/App/WCM/main.nsf/vw_ByID/medzinarodne_zmluvy-vsetky_zmluvy&OpenDocument=Y&LANG=SK&PAGE_MEDZINARODNEZMLUVY-ALL-DWMCEA-7XRF9N=#{page_number}"
    end

    def is_acceptable?
      return true if document.css('#newsWrapperMain .tableRT2 tr td a').present?

      next_extractor = Etl::MzvsrContractsPageExtraction.new(page_number + 1)

      next_extractor.download

      return next_extractor.document.css('#newsWrapperMain .tableRT2 tr td a').present?
    end

    def pages
      uris = []

      document.css('#newsWrapperMain .tableRT2 tr td a[title]').each do |link|
        uris << "#{base_url}#{link['href']}"
      end

      uris
    end

    def perform
      if is_acceptable?
        pages.each do |uri|
          Delayed::Job.enqueue(Etl::MzvsrContractExtraction.new(uri))
        end
      end
    end
  end
end
