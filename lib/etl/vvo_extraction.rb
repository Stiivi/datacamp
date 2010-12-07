# encoding: UTF-8

require 'fileutils'

module Etl
  class VvoExtraction < Struct.new(:start_id, :batch_limit, :id)
    def perform
      puts "downloading: #{id}"
      download(id)
      puts "parsing: #{id}"
      procurement_hash = parse(id)
      unless procurement_hash == :unknown_announcement_type
        puts "saving: #{id}"
        save(procurement_hash, id)
        update_last_processed(id)
      end
    end
    
    def download(id)
      system("wget", "-qE", "-P", '/tmp/vvo_extraction', document_url(id))
    end
    
    def cleanup
      FileUtils.rm_rf '/tmp/vvo_extraction'
    end
    
    def update_last_processed(id)
      config.update_attribute(:last_processed_id, id)
    end
    
    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end
    
    def document_url(id)
      "http://www.e-vestnik.sk/EVestnik/Detail/#{id}"
    end
    
    def save(procurement_hash, document_id)
      procurement_model = Class.new StagingRecord
      procurement_model.set_table_name "sta_procurements2"
      
      procurement_hash[:suppliers].each do |supplier|
        procurement_model.create!({
            :document_id => document_id,
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
            :source_url => document_url(document_id),
            :date_created => Time.now,
            :note => supplier[:note]})
      end
    end
    
    def parse(id)
      if File.exists?("/tmp/vvo_extraction/#{id}.html")
        file_content = Iconv.conv('utf-8', 'cp1250', File.open("/tmp/vvo_extraction/#{id}.html").read).gsub("&nbsp;",' ')
        doc = Nokogiri::HTML(file_content)
      
        checked_value = doc.xpath "//div[@id='innerMain']/div/h2"
        if checked_value.nil?
            return :unknown_announcement_type
        else
          document_type = checked_value.inner_text
          if document_type.match(/V\w+$/)
              return digest(doc)
          else
            return :unknown_announcement_type
          end
        end
      else
        return :unknown_announcement_type
      end
    end
    
    def digest(doc)
      procurement_id = doc.xpath("//div[@id='innerMain']/div/h2").inner_text

      bulletin_and_year = doc.xpath("//div[@id='innerMain']/div/div").inner_text
      bulletin_and_year_content = bulletin_and_year.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
      bulletin_id = bulletin_and_year_content[1] unless bulletin_and_year_content.nil?
      year = bulletin_and_year_content[2] unless bulletin_and_year_content.nil?
      
      suppliers = []
      max_procurement_words = 12
      
      customer_ico = customer_name = procurement_subject = ''
      
      doc.xpath("//span[@class='nadpis']").each do |element|
        if element.inner_text.match(/ODDIEL\s+I\W/)
          customer_information = element.next_sibling
          customer_name = customer_information.xpath("/tbody/tr[2]/td[2]/table/tbody/tr[1]/td[@class='hodnota']/span/span").inner_text.strip
          customer_name = customer_information.xpath("/tbody/tr[2]/td[2]/table/tbody/tr[1]/td[@class='hodnota']/span").inner_text.strip if customer_name.empty?
          customer_ico = customer_information.xpath("/tbody/tr[2]/td[2]/table/tbody/tr[2]/td[@class='hodnota']//span[@class='hodnota']").inner_text.strip
        elsif element.inner_text.match(/ODDIEL\s+II\W/)
          contract_information = element.next_sibling
          contract_information.xpath(".//td[@class='kod']").each do |code|
            if code.inner_text.match(/II\.*.*?[^\d]4[^\d]$/)
              procurement_subject = code.next_sibling.xpath(".//span[@class='hodnota']").inner_text
              procurement_subject = procurement_subject.split[0..max_procurement_words].join(' ')
            end
          end
        elsif element.inner_text.match(/ODDIEL\s+V\W/)
          supplier_information = element.next_sibling
          supplier = {}
          supplier_information.xpath(".//td[@class='kod']").each do |code|
            if code.inner_text.match(/V\.*.*?[^\d]1[^\d]$/)
              #supplier[:date] = Date.parse((code.following_siblings.first/"//span[@class='hodnota']").inner_text)
            elsif code.inner_text.match(/V\.*.*?[^\d]3[^\d]$/)
              supplier = {}
              supplier_details = code.parent.next_sibling.xpath(".//td[@class='hodnota']//span[@class='hodnota']")
              supplier[:supplier_name] = supplier_details[0].inner_text; supplier[:supplier_ico] = supplier_details[1].inner_text.gsub(' ', ''); supplier[:supplier_ico_evidence] = "";
              supplier[:supplier_ico] = Float(supplier[:supplier_ico]) rescue supplier[:supplier_ico]
              supplier[:note] = "Zahranicne IČO: #{supplier[:supplier_ico]}" if supplier[:supplier_ico] && supplier[:supplier_ico].class != Float
            elsif code.inner_text.match(/^V\.*4/)
              price_detail = code.parent.next_sibling
              while price_detail do
                if price_detail.xpath(".//span[@class='podnazov']").inner_text.match(/konečná/) || price_detail.xpath(".//span[@class='nazov']").inner_text.match(/konečná/)
                  price = price_detail.next_sibling.xpath(".//span[@class='hodnota']")
                  supplier[:is_price_part_of_range] = price_detail.next_sibling.xpath(".//span[@class='podnazov']").inner_html.downcase.match(/najnižšia/) ? true : false
                  supplier[:price] = price[0].inner_text.gsub(' ', '').gsub(',','.').to_f
                  supplier[:currency] = if price.inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                  supplier[:vat_included] = !price_detail.next_sibling.xpath(".//span[@class='hodnota']").inner_text.downcase.match(/bez/) && !price_detail.next_sibling.next_sibling.xpath(".//span[@class='hodnota']").inner_text.downcase.match(/bez/)
                  suppliers << supplier
                end
                price_detail = price_detail.next_sibling
              end
              #code.parent.following_siblings.each do |price_detail|
              #end
            end
          end
        end
      end
      
      {:customer_ico => customer_ico.to_i, :customer_name => customer_name, :customer_ico_evidence => "", :suppliers => suppliers, :procurement_subject => procurement_subject, :year => year.to_i, :bulletin_id => bulletin_id.to_i, :procurement_id => procurement_id}
    end
    
    def after(job)
      if id == (start_id + batch_limit)
        if config.last_processed_id > start_id
          ((id+1)..(id+1+config.batch_limit)).each do |i|
            Delayed::Job.enqueue Etl::VvoExtraction.new(id+1, config.batch_limit, i)
          end
        else
          config.update_attribute(:start_id, id+1)
          cleanup
        end
      end
    end
  end
end