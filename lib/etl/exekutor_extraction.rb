# -*- encoding : utf-8 -*-

module Etl
  class ExekutorExtraction
    
    def document_url
      "http://www.ske.sk/ExecutorList/"
    end
    
    def download
      Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
    end
    
    def is_acceptable?(document)
      document.xpath("//div[@id='main']").present?
    end
    
    def digest(doc)
      doc.xpath("//div[@id='main']/div").map do |list_item|
        {
          :name => list_item.xpath("./h5").inner_text.strip,
          :address => (list_item.inner_html.match(/<strong>Adresa:<\/strong>(?<address> .*?)<br>/)[:address].strip rescue nil),
          :telephone => (list_item.inner_html.match(/<strong>Tel.:<\/strong>(?<tel> .*?)<br>/)[:tel].strip rescue nil),
          :fax => (list_item.inner_html.match(/<strong>Fax:<\/strong>(?<fax> .*?)<br>/)[:fax].strip rescue nil),
          :email => (list_item.inner_html.match(/<strong>E-mail:<\/strong>(?<email> [^ @]+@[^ @]+\.[a-zA-Z]{2,4})/)[:email].strip rescue nil)
        }
      end
    end
    
    
    def save(executors_hash)
      Staging::StaExecutor.create(executors_hash)
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