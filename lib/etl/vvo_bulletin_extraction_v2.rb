# -*- encoding : utf-8 -*-

module Etl
  class VvoBulletinExtractionV2
    include Etl::Shared::VvoIncludes

    attr_reader :document_url, :report_extraction

    def initialize(document_url, report_extraction = false)
      @document_url = document_url
      @report_extraction = report_extraction
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction_v2')
    end

    def download
      Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
    end

    def document
      @document ||= download
    end

    def perform
      document_ids = {
          notice: [],
          performance: []
      }

      css_links = document.css('#layout-column_column-2 .portlet-body a')
      any_valid_link = false
      css_links.each do |css_link|
        valid_link = css_link.inner_text.match(/(\d*)(\ )(\-)(\ )(...)(\ )(\:)(\ )(\D*)/u)
        any_valid_link = true if valid_link
        document_type = valid_link ? valid_link[5] : nil
        dataset_type = Etl::VvoExtractionV2.dataset_type(document_type)

        # find dataset type by etl vvo extraction v2
        if dataset_type
          href = css_link.attributes['href'].text
          document_id = href.match(/(\D*)(\/)(\d*)(\D*)/u)[3].to_i
          document_ids[dataset_type] << document_id
        end
      end

      if any_valid_link
        # Problem when documents_ids is empty
        if document_ids[:notice].empty? && document_ids[:performance].empty?
          code = document_url.scan(/eVestnikPortlets_vydanie\=(\d*)/)
          if code.size == 1 && code.first.size == 1
            code = code.first.first
          else
            code = "url"
          end
          update_report_object(:download_bulletin, code, document_url) if report_extraction
        end

        # For each document type
        [:notice, :performance].each do |dataset_type|
          dataset = Etl::VvoExtractionV2.dataset_table(dataset_type)
          existing_document_ids = dataset.where(document_id: document_ids[dataset_type]).map(&:document_id)
          missed_documents = document_ids[dataset_type] - existing_document_ids
          missed_documents.each do |document_id|
            # missed
            update_report_object_depth_2(EtlConfiguration::VVO_V2_KEYS_BY_TYPES[dataset_type], :missed, document_id, "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{document_id}") if report_extraction
            # run extractor
            Delayed::Job.enqueue Etl::VvoExtractionV2.new(document_id, report_extraction)
          end
        end
      else
        Delayed::Job.enqueue Etl::VvoBulletinExtractionV2.new(document_url, report_extraction)
      end
    end

    def after(job)
    end

    def self.config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction_v2')
    end

    def self.update_last_run_time
      config.update_attribute(:last_run_time, Time.now)
    end

    def self.update_last_processed_id(last_processed_id)
      config.update_attribute(:last_processed_id, last_processed_id)
    end

    # Extract all new bulletins in year

    def self.extract_new_current_bulletins
      year = Date.today.year
      last_processed_bulletin_code = config.last_processed_id
      bulletins = all_bulletins_in_year(year)
      last_current_bulletin_code = bulletins.keys.sort.last
      last_processed_bulletin_code = 0 if last_processed_bulletin_code > last_current_bulletin_code
      ((last_processed_bulletin_code+1)..last_current_bulletin_code).each do |bulletin_code|
        Delayed::Job.enqueue Etl::VvoBulletinExtractionV2.new(bulletins[bulletin_code])
      end
      update_last_processed_id(last_current_bulletin_code)
      update_last_run_time
    end


    # Extract all bulletins in year

    def self.clear_report
      config.clear_report!
    end

    def self.extract_all_bulletins(year)
      all_bulletins_in_year(year).values.each do |bulletin_url|
        Delayed::Job.enqueue Etl::VvoBulletinExtractionV2.new(bulletin_url, true)
      end
      update_last_run_time
    end

    def self.all_bulletins_in_year(in_year)
      document_url = "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/all"
      document = Nokogiri::HTML(Typhoeus::Request.get(document_url).body)

      links = {}
      document.css('#layout-column_column-2 .portlet-body a').each_with_index do |css_link|
        if css_link.inner_text.include? '/'
          href = css_link.attributes['href'].text
          bulletin_and_year = css_link.inner_text.gsub(/ /, '').match(/.*?(\d*)\/(\d*)/u)
          year = bulletin_and_year[2].to_i
          bulletin_code = bulletin_and_year[1].to_i
          links[bulletin_code] = href if year == in_year
        end
      end

      # report
      if links.empty?
        config.update_report!(:download_bulletins, "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/all") if report_extraction
      end

      links
    end

  end
end
