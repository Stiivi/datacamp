# encoding: UTF-8
module Etl
  class VvoExtraction < Struct.new(:start_id, :end_id, :id)
    def perform
      puts "downloading: #{id}"
      download(id)
      puts "parsing: #{id}"
      procurement_hash = parse(id)
      unless procurement_hash == :unknown_announcement_type
        puts "savind: #{id}"
        save(procurement_hash, id)
      end
    end
    
    def download(id)
      system("wget", "-qE", "-P", '/tmp/vvo_extraction', document_url(id))
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
      file_content = Iconv.conv('utf-8', 'cp1250', File.open("/tmp/vvo_extraction/#{id}.html").read).gsub("&nbsp;",' ')
      doc = Hpricot(file_content)
      
      checked_value = (doc/"//div[@id='innerMain']/div/h2")
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
    end
    
    def digest(doc)
      procurement_id = (doc/"//div[@id='innerMain']/div/h2").inner_text

      bulletin_and_year = (doc/"//div[@id='innerMain']/div/div").inner_text
      bulletin_and_year_content = bulletin_and_year.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
      bulletin_id = bulletin_and_year_content[1] unless bulletin_and_year_content.nil?
      year = bulletin_and_year_content[2] unless bulletin_and_year_content.nil?
      
      suppliers = []
      max_procurement_words = 12
      
      customer_ico = customer_name = procurement_subject = ''
      
      (doc/"//span[@class='nadpis']").each do |element|
        if element.inner_text.match(/ODDIEL\s+I\W/)
          customer_information = element.following_siblings.first
          customer_name = (customer_information/"/tbody/tr[2]/td[2]/table/tbody/tr[1]/td[@class='hodnota']/span/span").inner_text.strip
          customer_name = (customer_information/"/tbody/tr[2]/td[2]/table/tbody/tr[1]/td[@class='hodnota']/span").inner_text.strip if customer_name.empty?
          customer_ico = (customer_information/"/tbody/tr[2]/td[2]/table/tbody/tr[2]/td[@class='hodnota']//span[@class='hodnota']").inner_text.strip
        elsif element.inner_text.match(/ODDIEL\s+II\W/)
          contract_information = element.following_siblings.first
          (contract_information/"//td[@class='kod']").each do |code|
            if code.inner_text.match(/II\.*.*?[^\d]4[^\d]$/)
              procurement_subject = (code.following_siblings.first/"//span[@class='hodnota']").inner_text
              procurement_subject = procurement_subject.split[0..max_procurement_words].join(' ')
            end
          end
        elsif element.inner_text.match(/ODDIEL\s+V\W/)
          supplier_information = element.following_siblings.first
          supplier = {}
          (supplier_information/"//td[@class='kod']").each do |code|
            if code.inner_text.match(/V\.*.*?[^\d]1[^\d]$/)
              #supplier[:date] = Date.parse((code.following_siblings.first/"//span[@class='hodnota']").inner_text)
            elsif code.inner_text.match(/V\.*.*?[^\d]3[^\d]/)
              supplier = {}
              supplier_details = code.parent.following_siblings.first/"//td[@class='hodnota']//span[@class='hodnota']"
              supplier[:supplier_name] = supplier_details[0].inner_text; supplier[:supplier_ico] = supplier_details[1].inner_text.gsub(' ', ''); supplier[:supplier_ico_evidence] = "";
              supplier[:supplier_ico] = Float(supplier[:supplier_ico]) rescue supplier[:supplier_ico]
              supplier[:note] = "Zahranicne IČO: #{supplier[:supplier_ico]}" if supplier[:supplier_ico] && supplier[:supplier_ico].class != Float
            elsif code.inner_text.match(/V\.*.*?[^\d]4[^\d]/)
              code.parent.following_siblings.each do |price_detail|
                break unless (price_detail/"//td[@class='kod']").inner_text.empty?
                if (price_detail/"//span[@class='podnazov']").inner_text.match(/konečná/) || (price_detail/"//span[@class='nazov']").inner_text.match(/konečná/)
                  price = (price_detail.following_siblings.first/"//span[@class='hodnota']")
                  supplier[:is_price_part_of_range] = (price_detail.following_siblings.first/"//span[@class='podnazov']").inner_html.downcase.match(/najnižšia/) ? true : false
                  supplier[:price] = price[0].inner_text.gsub(' ', '').gsub(',','.').to_f
                  supplier[:currency] = if price.inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                  supplier[:vat_included] = !(price_detail.following_siblings[0]/"//span[@class='hodnota']").inner_text.downcase.match(/bez/) && !(price_detail.following_siblings[1]/"//span[@class='hodnota']").inner_text.downcase.match(/bez/)
                  suppliers << supplier
                end
              end
            end
          end
        end
      end
      
      {:customer_ico => customer_ico.to_i, :customer_name => customer_name, :customer_ico_evidence => "", :suppliers => suppliers, :procurement_subject => procurement_subject, :year => year.to_i, :bulletin_id => bulletin_id.to_i, :procurement_id => procurement_id}
    end
    
    def after(job)
      # if id == end_id && id < 100
      #   (id+1..id+20).each do |i|
      #     Delayed::Job.enqueue Etl::VvoExtraction.new(id+1, id+20, i)
      #   end
      # end
    end
  end
end