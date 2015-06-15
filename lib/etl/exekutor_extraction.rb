# -*- encoding : utf-8 -*-
require 'etl/page_loader'

module Etl
  class ExekutorExtraction
    attr_reader :page_loader, :document_url, :storage, :page_class

    def initialize(options = {})
      @page_loader = options.fetch(:page_loader) { Etl::PageLoader }
      @page_class = options.fetch(:page_class) { Etl::ExekutorExtraction::ListingPage }
      @storage = options.fetch(:storage) { Kernel::DsExecutor }
      @document_url = options.fetch(:document_url) { "http://www.ske.sk/zoznam-exekutorov/" }
    end

    def perform
      store_executors
    end

    def store_executors
      if elements_to_parse_count > 0
        storage.suspend_all
        active_executor_ids = page.executors.map { |executor_hash| storage.store_executor(executor_hash).id }
        storage.publish_with_ids(active_executor_ids)
      end
    end

    def self.update_last_run_time
      EtlConfiguration.find_by_name('executor_extraction').update_attribute(:last_run_time, Time.now)
      DatasetDescription.find_by_identifier('executors').update_attribute(:data_updated_at, Time.zone.now)
    end

    def elements_to_parse_count
      page.executors_count
    end

    def page
      @page ||= page_loader.load_by_get(document_url, page_class)
    end

    class ListingPage
      attr_reader :document

      def initialize(document)
        @document = document
      end

      def executors_count
        executors.count
      end

      def executors
        return [] unless acceptable?

        @executors ||= begin
          document.xpath("//table[@id='executors']//tr[@class='listtr']")[1..-2].map do |list_item_tr|
            td_1 = list_item_tr.xpath(".//td[1]")
            td_2 = list_item_tr.xpath(".//td[2]")
            address = (td_2.inner_html.match(/<strong>Adresa: <\/strong>(?<address>.*?)<br>/)[:address].strip rescue nil)
            if address
              street = address.split(',').first
              city = address.split(',').last.match(/(?<zip>\d+ \d+|\d+)\s?(?<city>[^\d]+\d?)/)[:city] if address.split(',').last.match(/(?<zip>\d+ \d+|\d+)\s?(?<city>[^\d]+\d?)/).present?
              zip = address.split(',').last.match(/ (?<zip>\d+ \d+|\d+)/)[:zip] if address.split(',').last.match(/ (?<zip>\d+ \d+|\d+)/).present?
            end
            {
                :name => td_1.inner_text.strip,
                :street => street,
                :zip => zip,
                :city => city,
                :telephone => (td_2.inner_html.match(/<strong>Tel.: <\/strong>(?<tel>.*?)<br>/)[:tel].strip rescue nil),
                :fax => (td_2.inner_html.match(/<strong>Fax: <\/strong>(?<fax>.*?)<br>/)[:fax].strip rescue nil),
                :email => (td_2.inner_html.match(/<strong>E-mail: <\/strong>(?<email>[^ @]+@[^ @]+\.[a-zA-Z]{2,4})/)[:email].strip rescue nil)
            }
          end
        end
      end

      private

      def acceptable?
        document.xpath("//table[@id='executors']").present?
      end
    end
  end
end
