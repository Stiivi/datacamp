require 'fileutils'
require 'csv'

module Etl
  class OtvorenezmluvyExtraction
    def config
      @configuration ||= EtlConfiguration.find_by_name('otvorenezmluvy_extraction')
    end

    def url
      "http://otvorenezmluvy.sk/data/"
    end

    def perform
      acceptable_links(list).each do |link|
        puts "Processing file: #{link}"
        parse(download_file(link))
        config.update_attribute(:start_id, filename_to_id(link)+1)
      end
    end

    private
      def parse(data)
        CSV.parse(data, headers: true, header_converters: :symbol) do |row|
          Kernel::DsOtvorenezmluvy.create!(name: row[:name],
                                           otvorenezmluvy_type: row[:type],
                                           department: row[:department],
                                           customer: row[:customer],
                                           supplier: row[:supplier],
                                           supplier_ico: row[:supplier_ico],
                                           contracted_amount: row[:contracted_amount],
                                           total_amount: row[:total_amount],
                                           published_on: row[:published_on],
                                           effective_from: row[:effective_from],
                                           expires_on: row[:expires_on],
                                           note: row[:note],
                                           page_count: row[:pocet_stran],
                                           record_status: Dataset::RecordStatus.find(:published),
                                           source_url: "http://otvorenezmluvy.sk/documents/#{row[:id]}"
                                          )
        end
      end

      def download_file(link)
        content = ''
        open(link) do |f|
          gz = Zlib::GzipReader.new f
          content = gz.read
          gz.finish
        end
        content
      end

      def list
        Nokogiri::HTML(Typhoeus::Request.get(url).body)
      end

      def acceptable_links(list)
        list.xpath("//a[contains(@href, 'csv.gz')]").to_a.keep_if do |anchor|
          href = anchor.attribute('href').value
          start_id = config.start_id
          href.match(/\d\.csv\.gz$/) && filename_to_id(href) > start_id
        end.map{|l| URI.join(url, l.attribute('href').value).to_s  }
      end

      def filename_to_id(href)
        href.split('_').last.split('.').first.gsub('-', '').to_i
      end

  end
end

