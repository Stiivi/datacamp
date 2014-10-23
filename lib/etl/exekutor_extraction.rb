# -*- encoding : utf-8 -*-

module Etl
  class ExekutorExtraction

    def document_url
      "http://www.ske.sk/zoznam-exekutorov/"
    end

    def download
      Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
    end

    def self.update_last_run_time
      EtlConfiguration.find_by_name('executor_extraction').update_attribute(:last_run_time, Time.now)
      DatasetDescription.find_by_identifier('executors').update_attribute(:data_updated_at, Time.zone.now)
    end

    def is_acceptable?(document)
      document.xpath("//table[@id='executors']").present?
    end

    def elements_to_parse_count
      download.xpath("//table[@id='executors']//tr[@class='listtr']").count - 2 # ignore first and last
    end

    def digest(doc)
      doc.xpath("//table[@id='executors']//tr[@class='listtr']")[1..-2].map do |list_item_tr|
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


    def save(executors_hash)
      Kernel::DsExecutor.update_all(record_status: 'suspended')
      active_executor_ids = executors_hash.map do |executor_hash|
        executor = Kernel::DsExecutor.find_or_initialize_by_name_and_city(executor_hash[:name], executor_hash[:city])
        executor.update_attributes(executor_hash)
        executor.id
      end
      Kernel::DsExecutor.where(_record_id: active_executor_ids).update_all(record_status: 'published')
    end

    def perform
      document = download
      if is_acceptable?(document)
        executors_hash = digest(document)
        save(executors_hash)
      end
    end

  end
end
