# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class VvoExtraction < Etl::Extraction
    @@procurement_subject_word_length = 12

    def document_url(id)
      "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{id}"
    end
    def download(id)
      Nokogiri::HTML(Typhoeus::Request.get(document_url(id)).body)
    end

    def is_acceptable?(document)
      document_type = document_type(document) # nil, other, problem_1, standard
      acceptable = [:standard, :problem_1].include? document_type

      if single_extraction
        # if not acceptable and single_extraction - must notify with email
        case document_type
          when nil
            Delayed::Job.enqueue Etl::VvoExtraction.new(nil,nil,id,true)
          when :other
            EtlMailer.vvo_parser_problem(document_url(id), :acceptable).deliver
          else
        end
      end

      acceptable
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end

    def document_type(document)
      if document.xpath("//div[@class='oznamenie']/div[@class='MainHeader'][1]").inner_text.match(/V\w+$/)
        :standard
      elsif document.xpath("//div[@class='oznamenie']/./h2[@class='document_number_and_code'][1]").inner_text.match(/V\w+$/)
        :problem_1
      elsif document.xpath("//div[@class='oznamenie']").any?
        debugger
        :other
      else
        nil
      end
    end

    def basic_information(document)
      header = document.xpath("//div[@class='oznamenie']")

      procurement_id = bulletin_id = year = nil

      case document_type(document)
        when :standard
          procurement_id = header.xpath("./div[@class='MainHeader'][1]").inner_text
          bulletin_and_year = header.xpath('./div[2]').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u) || header.xpath('./div[3]').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
        when :problem_1
          procurement_id = document.xpath("//div[@class='oznamenie']/./h2[@class='document_number_and_code'][1]").inner_text
          bulletin_and_year = header.xpath('./div[1]').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
        else
          bulletin_and_year = nil
      end

      unless bulletin_and_year.nil?
        bulletin_id = bulletin_and_year[1]
        year = bulletin_and_year[2]
      end

      {:procurement_id => procurement_id, :bulletin_id => bulletin_id.to_i, :year => year.to_i}
    end

    def customer_information(document)
      customer_information_hash = {}

      case document_type(document)
        when :standard
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+I\W/)
              customer_information = element.next_sibling.next_sibling
              customer_information_hash[:customer_name] = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']/span[1]").inner_text.strip
              customer_information_hash[:customer_ico] = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']/span[3]").inner_text.strip

              break
            end
          end
        when :problem_1
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+I\W/)
              customer_information = element.xpath(".//table")[0].xpath(".//tr[2]//table[1]//td[@class='hodnota']")
              customer_information_hash[:customer_name] = customer_information[0].xpath(".//span[@class='hodnota']").inner_text
              customer_information_hash[:customer_ico] = customer_information[1].xpath(".//span[@class='hodnota']").inner_text
              break
            end
          end
      end

      customer_information_hash
    end

    def contract_information(document)
      contract_information_hash = {}

      case document_type(document)
        when :standard
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+II\W/)
              contract_information = element.next_sibling.next_sibling
              contract_information.xpath(".//span[@class='code']").each do |code|
                if code.inner_text.strip.match(/^II.1.1/)
                  procurement_subject = code.parent.next_sibling.next_sibling.inner_text
                  contract_information_hash[:procurement_subject] = procurement_subject.split[0..@@procurement_subject_word_length].join(' ')
                end
              end
            end
          end
        when :problem_1
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+II\W/)
              element.xpath(".//table")[0].xpath(".//tr").each do |tr|
                if tr.inner_text.strip.match(/^II.1.1/)
                  procurement_subject = tr.xpath(".//td")[1].xpath(".//span[@class='hodnota']").inner_text
                  procurement_subject = tr.next.xpath(".//td")[1].xpath(".//span[@class='hodnota']").inner_text if procurement_subject.blank?
                  contract_information_hash[:procurement_subject] = procurement_subject.strip
                end
              end
            end
          end
      end
      contract_information_hash
    end

    def suppliers_information(document)
      suppliers = []

      case document_type(document)
        when :standard
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+V\W/)
              supplier_information = element.next_sibling.next_sibling
              supplier = {}
              supplier_information.xpath(".//span[@class='code']").each do |code|
                if code.inner_text.strip.match(/V\.*.*?[^\d]3[^\d]$/)
                  supplier = {}
                  supplier[:supplier_name] = code.parent.next_sibling.next_sibling.xpath(".//span[@class='titleValue']//span[1]").inner_text.strip

                  supplier[:supplier_ico] =code.parent.next_sibling.next_sibling.xpath(".//span[@class='titleValue']//span[3]").inner_text.strip.gsub(' ', '')
                  supplier[:supplier_ico] = (Float(supplier[:supplier_ico]) rescue supplier[:supplier_ico] )
                  supplier[:note] = "Zahranicne IČO: #{supplier[:supplier_ico]}" if supplier[:supplier_ico] && supplier[:supplier_ico].class != Float
                elsif code.inner_text.strip.match(/V\.*.*?[^\d]4[^\d]$/)
                  price_detail = code.parent.next_sibling.next_sibling
                  if price_detail.inner_text.match(/Hodnota udelených (cien|ocenení) a\/alebo odmien(.*)DPH/)
                    supplier[:vat_included] = !price_detail.inner_text.match(/Hodnota udelených (cien|ocenení) a\/alebo odmien(.*)(.)DPH/)[2].downcase.match(/bez/)

                    prices = price_detail.xpath(".//span")
                    supplier[:price] = prices[0].inner_text.gsub(' ', '').gsub(',','.').to_f
                    supplier[:currency] = if prices[1].inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                    supplier[:is_price_part_of_range] = false
                  else
                    if price_detail.next_sibling.next_sibling.xpath(".//span").inner_text.match(/(predpokladaná celková hodnota zákazky)|konečná/)
                      price_detail = price_detail.next_sibling.next_sibling
                    end
                    if price_detail.next_sibling.next_sibling.next_sibling.xpath(".//span").inner_text.match(/(predpokladaná celková hodnota zákazky)|konečná/)
                      price_detail = price_detail.next_sibling.next_sibling.next_sibling
                    end
                    while price_detail && price_detail.xpath(".//span").inner_text.match(/(predpokladaná celková hodnota zákazky)|konečná/) do
                      if price_detail.next_sibling.next_sibling.inner_text.downcase.strip.match(/jedna hodnota/)
                        price_detail = price_detail.next_sibling.next_sibling
                      end
                      price = price_detail.next_sibling.next_sibling.xpath(".//span[1]").inner_text.strip

                      supplier[:is_price_part_of_range] = price_detail.next_sibling.next_sibling.next_sibling.next_sibling.inner_text.downcase.match(/najnižšia/) ? true : false
                      if price.present?
                        supplier[:price] = price.gsub(' ', '').gsub(',','.').to_f
                        supplier[:currency] = if price_detail.next_sibling.next_sibling.inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                        supplier[:vat_included] = !price_detail.next_sibling.next_sibling.next_sibling.inner_text.downcase.downcase.match(/bez/)
                      end

                      price_detail = (price_detail.next_sibling.next_sibling.next_sibling.next_sibling.next_sibling rescue nil)
                    end
                  end
                  suppliers << supplier
                  supplier = {}
                end
              end
              unless supplier.empty?
                suppliers << supplier
              end
            end
          end
        when :problem_1
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+V\W/)
              supplier = {}
              supplier_information = element.xpath(".//table[1]//tr[2]//td[2]//table[1]//tr")
              supplier_information = element.xpath(".//table[1]//tr[1]//td[1]//table[1]//tr") if supplier_information.empty?
              supplier_information = element.xpath(".//table[1]//tr[1]//td[2]//table[1]//tr") if supplier_information.empty?
              supplier_information.each do |code|
                if code.inner_text.match(/Zmluva k(.)časti č\.\:\ (\d*)/)
                  suppliers << supplier unless supplier.empty?
                  supplier = {}.dup
                elsif code.inner_text.strip.match(/V(\.)(\d\.)?3(\D*)$/)
                  supplier[:supplier_name] = code.next.xpath(".//table[1]//tr")[0].inner_text.strip
                  ico = code.next.xpath(".//table[1]//tr[2]//span[@class='hodnota']").inner_text.strip.gsub(' ','')
                  supplier[:supplier_ico] = ico if code.next.xpath(".//table[1]//tr[2]").inner_text.match(/I(Č|C)O/)

                  supplier[:supplier_ico] = (Float(supplier[:supplier_ico]) rescue supplier[:supplier_ico] )
                  supplier[:note] = "Zahranicne IČO: #{supplier[:supplier_ico]}" if supplier[:supplier_ico] && supplier[:supplier_ico].class != Float

                  # prices
                elsif code.inner_text.match(/Hodnota udelených (cien|ocenení) a\/alebo odmien(.*)DPH/)
                  supplier[:vat_included] = !code.inner_text.match(/Hodnota udelených (cien|ocenení) a\/alebo odmien(.*)(.)DPH/)[2].downcase.match(/bez/)

                  prices = code.xpath(".//span[@class='hodnota']")
                  supplier[:price] = prices[0].inner_text.gsub(' ', '').gsub(',','.').to_f
                  supplier[:currency] = if prices[1].inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                  supplier[:is_price_part_of_range] = false
                elsif code.inner_text.match(/Celková konečná hodnota zákazky:/)
                  prices_with_range = code.next.xpath(".//span[@class='podnazov']")
                  if prices_with_range && prices_with_range[0].inner_text.match(/Najnižšia ponuka/)
                    supplier[:is_price_part_of_range] = true
                  else
                    supplier[:is_price_part_of_range] = false
                  end
                    prices = code.next.xpath(".//span[@class='hodnota']")

                    supplier[:price] = prices.first.inner_text.gsub(' ', '').gsub(',','.').to_f
                    supplier[:currency] = if prices.last.inner_text.downcase.match(/sk|skk/) then 'SKK' else 'EUR' end
                    if code.next.next.inner_text.downcase.match(/bez/)
                      supplier[:vat_included] = false
                    elsif code.next.next.next.inner_text.downcase.match(/bez/)
                      supplier[:vat_included] = false
                    else
                      supplier[:vat_included] = true
                    end
                end
              end
              suppliers << supplier unless supplier.empty?
            end
          end
      end

      {:suppliers => suppliers}
    end

    def digest(document)
      basic_information(document).merge(contract_information(document)).merge(customer_information(document)).merge(suppliers_information(document))
    end

    def save(procurement_hash)
      # Empty suppliers - notification
      if procurement_hash[:suppliers].empty?
        EtlMailer.vvo_parser_problem(document_url(id), :suppliers).deliver
      end

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

    # Fix bad year and bulletin_id

    def self.update_bulletin_id_and_years
      Staging::StaProcurement.where(bulletin_id: 0).each do |sta_procurement|
        extraction = Etl::VvoExtraction.new
        document = extraction.download(sta_procurement.document_id)
        basic_information = extraction.basic_information(document)
        sta_procurement.update_attributes(basic_information)
      end
    end

    # Fix old source urls

    def self.update_old_source_urls
      all_bulletins_hash = all_bulletins
      Staging::StaProcurement.where("source_url LIKE ?", 'http://www.e-vestnik.sk/EVestnik/Detail/%').each do |sta_procurement|
        self.update_source_url_and_document_id sta_procurement, all_bulletins_hash
      end
    end

    def self.update_source_url_and_document_id(sta_procurement, all_bulletins)
      key = "#{sta_procurement.bulletin_id}/#{sta_procurement.year}"
      url = all_bulletins[key]

      document = Nokogiri::HTML(Typhoeus::Request.get(url).body)
      find_text = sta_procurement.procurement_id
      elements = document.xpath("//a[contains(text(), '#{find_text}')]")
      source_url = nil
      if elements.count == 1
        source_url = elements.first.attributes["href"].text
      else
        while find_text.starts_with?'0' do
          find_text = find_text[1..-1]
        end
        elements = document.xpath("//a[contains(text(), '#{find_text}')]")
        if elements.count == 1
          source_url = elements.first.attributes["href"].text
        end
      end

      if source_url
        document_id = source_url.match(/http:\/\/www.uvo.gov.sk\/sk\/evestnik\/-\/vestnik\/(\d*)/u)[1].to_i
        document_url = "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{document_id}"

        document = Nokogiri::HTML(Typhoeus::Request.get(document_url).body)
        header = document.xpath("//div[@class='oznamenie']")

        procurement_id = header.xpath("./h2[1]").inner_text
        bulletin_and_year = header.xpath('./div[1]').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u) || header.xpath('./div[2]').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
        unless bulletin_and_year.nil?
          bulletin_id = bulletin_and_year[1]
          year = bulletin_and_year[2]
        end

        # UPDATE
        if sta_procurement.year == year.to_i && sta_procurement.bulletin_id == bulletin_id.to_i && sta_procurement.procurement_id == procurement_id
          sta_procurement.update_attributes(document_id: document_id, source_url: document_url)
        else
          puts "NOT CONSIST DATA #{document_url} #{sta_procurement.inspect}"
        end
      else
        puts "PROBLEM #{sta_procurement.inspect}"
      end
    end

    def self.all_bulletins
      document_url = "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/all"
      document = Nokogiri::HTML(Typhoeus::Request.get(document_url).body)

      links = {}
      document.css('#layout-column_column-2 .portlet-body a').each_with_index do |css_link|
        if css_link.inner_text.include? '/'
          href = css_link.attributes['href'].text
          bulletin_and_year = css_link.inner_text.gsub(/ /,'').match(/.*?(\d*)\/(\d*)/u)
          bulletin_id = bulletin_and_year[1]
          year = bulletin_and_year[2]
          links[ "#{bulletin_id}/#{year}" ] = href
        end
      end
      links
    end

  end
end
