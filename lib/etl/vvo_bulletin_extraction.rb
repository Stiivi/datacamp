# -*- encoding : utf-8 -*-

module Etl
  class VvoBulletinExtraction
    include Etl::Shared::VvoIncludes

    attr_reader :document_url

    def initialize(document_url)
      @document_url = document_url
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end

    def download
      Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
    end

    def document
      @document ||= download
    end

    def perform
      document_ids = []
      css_links = document.css('#layout-column_column-2 .portlet-body a')
      any_valid_link = false
      css_links.each do |css_link|
        valid_link = css_link.inner_text.match(/(\d*)(\ )(\-)(\ )(...)(\ )(\:)(\ )(\D*)/u)
        any_valid_link = true if valid_link
        if valid_link && valid_link[5].start_with?('V')
          href = css_link.attributes['href'].text
          document_id = href.match(/(\D*)(\/)(\d*)(\D*)/u)[3].to_i
          document_ids << document_id
        end
      end
      if any_valid_link

        # Problem when documents_ids is empty
        if document_ids.empty?
          code = document_url.scan(/eVestnikPortlets_vydanie\=(\d*)/)
          if code.size == 1 && code.first.size == 1
            code = code.first.first
          else
            code = "url"
          end
          update_report_object(:download_bulletin, code, document_url)
        end

        existing_document_ids = Staging::StaProcurement.where(document_id: document_ids).map(&:document_id)
        missed_documents = document_ids - existing_document_ids
        missed_documents.each do |document_id|
          # missed
          update_report_object_depth_2(:download_procurement, :missed, document_id, "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{document_id}")
          # run extractor
          Delayed::Job.enqueue Etl::VvoExtraction.new(nil, nil, document_id, true)
        end
      else
        Delayed::Job.enqueue Etl::VvoBulletinExtraction.new(document_url)
      end
    end

    def after(job)
    end

    def self.config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end

    def self.update_last_run_time
      config.update_attribute(:last_run_time, Time.now)
    end

    # Extract all bulletins in year

    def self.clear_report
      config.clear_report!
    end

    def self.extract_all_bulletins(year)
      all_bulletins_in_year(year).each do |bulletin_url|
        Delayed::Job.enqueue Etl::VvoBulletinExtraction.new(bulletin_url)
      end
    end

    def self.all_bulletins_in_year(in_year)
      document_url = "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/all"
      document = Nokogiri::HTML(Typhoeus::Request.get(document_url).body)

      links = []
      document.css('#layout-column_column-2 .portlet-body a').each_with_index do |css_link|
        if css_link.inner_text.include? '/'
          href = css_link.attributes['href'].text
          bulletin_and_year = css_link.inner_text.gsub(/ /, '').match(/.*?(\d*)\/(\d*)/u)
          year = bulletin_and_year[2].to_i
          links << href if year == in_year
        end
      end

      # report
      if links.empty?
        config.update_report!(:download_bulletins, "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/all")
      end

      links
    end

  end
end
