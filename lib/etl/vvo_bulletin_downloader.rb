# -*- encoding : utf-8 -*-

module Etl
  class VvoBulletinDownloader
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
      css_links.each do |css_link|
        valid_link = css_link.inner_text.match(/(\d*)(\ )(\-)(\ )(...)(\ )(\:)(\ )(\D*)/u)

        if valid_link && (valid_link[5].start_with?('V') || valid_link[5].start_with?('IP') || valid_link[5].start_with?('IZ'))
          href = css_link.attributes['href'].text
          document_id = href.match(/(\D*)(\/)(\d*)(\D*)/u)[3].to_i
          document_ids << document_id
        end

      end

      document_ids.each do |document_id|
        Etl::VvoBulletinDownloader.delay.download_document(document_id)
      end
    end

    def after(job)
    end

    # ----

    def self.download_document(id)
      url = "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{id}"
      html = Typhoeus::Request.get(url).body
      save("vvo/procurements/#{id}.html", html)
    end

    def self.save(name, html, options = {})
      filename = get_path(name, options)
      FileUtils.mkdir_p(File.dirname(filename))
      f = File.open(filename, "wb")
      begin
        f.write html
      ensure
        f.close
      end
    end

    def self.get_path(path, options = {})
      defaults = {
          :bucketize => true
      }
      options = defaults.merge(options)

      if options[:bucketize]
        path_chunks = path.split('/')
        output = []
        path_chunks.each do |chunk|
          numbers = chunk.scan(/[0-9]{3,}/).collect do |part|
            part.to_i / 1000 * 1000
          end
          output += numbers if numbers.any?
          output << chunk
        end
        "#{Rails.root}/data/#{Rails.env}/#{output.join('/')}"
      else
        "#{Rails.root}/data/#{Rails.env}/#{path}"
      end
    end

    # ----

    def self.config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end

    def self.download_all_bulletins(year)
      all_bulletins_in_year(year).each do |bulletin_url|
        Delayed::Job.enqueue Etl::VvoBulletinDownloader.new(bulletin_url)
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

      links
    end

  end
end
