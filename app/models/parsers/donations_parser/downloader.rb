module Parsers
  module DonationsParser
    class Downloader
      def initialize(parser_id, year)
        @parser_id = parser_id
        @year = year
      end

      def perform
        parser = get_config(@parser_id)
        parser.update_attribute(:status, EtlConfiguration::STATUS_ENUM[1])

        # html = ::Parsers::Support.download_via_post("https://registerkultury.gov.sk/granty#{@year}/zobraz_ziadosti.php",
        #             { filter: '', typ: 'vsetky' },
        #             Downloader.download_location(@year), bucketize: false)

        html = File.open( ::Parsers::Support.get_path(Downloader.download_location(@year), bucketize: false) , "rb" ).read
        Parser.parse(html, @year)
        download_paths = parser.download_path || []
        download_paths << Parser.parse_location(@year)

        parser.update_attribute(:status, EtlConfiguration::STATUS_ENUM[2])
        parser.update_attribute(:download_path, download_paths)
      rescue
        get_config(@parser_id).update_attribute(:status, EtlConfiguration::STATUS_ENUM[3])
      end

      def self.download_location(year)
        "registerkultury.gov.sk/proposals/#{year}.html"
      end

      private
        def get_config(parser_id)
          EtlConfiguration.find(parser_id)
        end
    end
  end
end
