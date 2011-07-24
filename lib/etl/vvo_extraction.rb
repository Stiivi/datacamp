# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class VvoExtraction < Etl::Extraction
    @@procurement_subject_word_length = 12

    def document_url(id)
      "http://www.e-vestnik.sk/EVestnik/Detail/#{id}"
    end
    
    def is_acceptable?(document)
      document.xpath("//div[@id='innerMain']/div/h2").inner_text.match(/V\w+$/)
    end
    
    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end
    
    def basic_information(document)
      header = document.xpath("//div[@id='innerMain']/div")
      
      procurement_id = header.xpath("./h2").inner_text
      bulletin_and_year = header.xpath('./div').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
      unless bulletin_and_year.nil?
        bulletin_id = bulletin_and_year[1]
        year = bulletin_and_year[2]
      end
      
      {:procurement_id => procurement_id, :bulletin_id => bulletin_id.to_i, :year => year.to_i}
    end
    
    def customer_information(document)
      customer_information_hash = {}
      
      document.xpath("//span[@class='nadpis']").each do |element|
        if element.inner_text.match(/ODDIEL\s+I\W/)
          customer_information = element.next_sibling
          customer_information_hash[:customer_name] = customer_information.xpath(".//tr[2]/td[2]/table/tbody/tr[1]/td[@class='hodnota']/span/span").inner_text.strip
          customer_information_hash[:customer_name] = customer_information.xpath(".//tr[2]/td[2]/table/tbody/tr[1]/td[@class='hodnota']/span").inner_text.strip if customer_information_hash[:customer_name].empty?
          customer_information_hash[:customer_ico] = customer_information.xpath(".//tr[2]/td[2]/table/tbody/tr[2]/td[@class='hodnota']//span[@class='hodnota']").inner_text.strip.to_i
          break
        end
      end
      customer_information_hash
    end
    
    def contract_information(document)
      contract_information_hash = {}
      
      document.xpath("//span[@class='nadpis']").each do |element|
        if element.inner_text.match(/ODDIEL\s+II\W/)
          contract_information = element.next_sibling
          contract_information.xpath(".//td[@class='kod']").each do |code|
            if code.inner_text.match(/^II.1.1/)
              procurement_subject = code.parent.xpath(".//span[@class='hodnota']").inner_text
              procurement_subject = code.parent.next_sibling.xpath(".//span[@class='hodnota']").inner_text if procurement_subject.empty?
              contract_information_hash[:procurement_subject] = procurement_subject.split[0..@@procurement_subject_word_length].join(' ')
            end
          end
        end
      end
      contract_information_hash
    end
    
    def suppliers_information(document)
      suppliers = []
      
      document.xpath("//span[@class='nadpis']").each do |element|
        if element.inner_text.match(/ODDIEL\s+V\W/)
          supplier_information = element.next_sibling
          supplier = {}
          supplier_information.xpath(".//td[@class='kod']").each do |code|
            if code.inner_text.match(/V\.*.*?[^\d]3[^\d]$/)
              supplier = {}
              supplier_details = code.parent.next_sibling.xpath(".//td[@class='hodnota']//span[@class='hodnota']")
              supplier[:supplier_name] = supplier_details[0].inner_text; supplier[:supplier_ico] = supplier_details[1].inner_text.gsub(' ', ''); #supplier[:supplier_ico_evidence] = "";
              supplier[:supplier_ico] = Float(supplier[:supplier_ico]) rescue supplier[:supplier_ico]
              supplier[:note] = "Zahranicne IČO: #{supplier[:supplier_ico]}" if supplier[:supplier_ico] && supplier[:supplier_ico].class != Float
            elsif code.inner_text.match(/V\.*.*?[^\d]4[^\d]$/)
              price_detail = code.parent.next_sibling
              while price_detail do
                if price_detail.xpath(".//span[@class='podnazov']").inner_text.match(/Začiatočná predpokladaná celková hodnota zákazky|konečná/) || price_detail.xpath(".//span[@class='nazov']").inner_text.match(/Začiatočná predpokladaná celková hodnota zákazky|konečná/)
                  price = price_detail.next_sibling.xpath(".//span[@class='hodnota']")
                  supplier[:is_price_part_of_range] = price_detail.next_sibling.xpath(".//span[@class='podnazov']").inner_html.downcase.match(/najnižšia/) ? true : false
                  supplier[:price] = price[0].inner_text.gsub(' ', '').gsub(',','.').to_f
                  supplier[:currency] = if price.inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                  supplier[:vat_included] = !price_detail.next_sibling.xpath(".//span[@class='hodnota']").inner_text.downcase.match(/bez/) && !price_detail.next_sibling.next_sibling.xpath(".//span[@class='hodnota']").inner_text.downcase.match(/bez/)
                  break if price_detail.xpath(".//span[@class='podnazov']").inner_text.match(/konečná/) || price_detail.xpath(".//span[@class='nazov']").inner_text.match(/konečná/)
                end
                price_detail = price_detail.next_sibling
              end
              suppliers << supplier
            end
          end
        end
      end
      
      {:suppliers => suppliers}
    end
    
    def digest(document)
      basic_information(document).merge(contract_information(document)).merge(customer_information(document)).merge(suppliers_information(document))
    end
    
    def save(procurement_hash)
      procurement_hash[:suppliers].each do |supplier|
        Staging::StaProcurement.create({
            :document_id => id,
            :year => procurement_hash[:year],
            :bulletin_id => procurement_hash[:bulletin_id],
            :procurement_id => procurement_hash[:procurement_id],
            :customer_ico => procurement_hash[:customer_ico],
            :customer_name => procurement_hash[:customer_name],
            :supplier_ico => supplier[:supplier_ico],
            :supplier_name => supplier[:supplier_name],
            :procurement_subject => procurement_hash[:procurement_subject],
            :price => supplier[:price],
            :is_price_part_of_range => supplier[:is_price_part_of_range],
            :currency => supplier[:currency],
            :is_vat_included => supplier[:vat_included],
            :customer_ico_evidence => procurement_hash[:customer_ico_evidence],
            :supplier_ico_evidence => supplier[:supplier_ico_evidence],
            :subject_evidence => "",
            :price_evidence => "",
            :source_url => document_url(id),
            :date_created => Time.now,
            :note => supplier[:note]})
      end
    end
    
    def enque_job(document_id)
      Delayed::Job.enqueue Etl::VvoExtraction.new(id+1, config.batch_limit, document_id)
    end
  end
end
