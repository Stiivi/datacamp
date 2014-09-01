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
      document.xpath("//div[@class='oznamenie']/div[@class='MainHeader'][1]").inner_text.match(/V\w+$/)
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction')
    end

    def basic_information(document)
      header = document.xpath("//div[@class='oznamenie']")

      procurement_id = header.xpath("./div[@class='MainHeader'][1]").inner_text
      bulletin_and_year = header.xpath('./div[2]').inner_text.gsub(/ /,'').match(/Vestník.*?(\d*)\/(\d*)/u)
      unless bulletin_and_year.nil?
        bulletin_id = bulletin_and_year[1]
        year = bulletin_and_year[2]
      end

      {:procurement_id => procurement_id, :bulletin_id => bulletin_id.to_i, :year => year.to_i}
    end

    def customer_information(document)
      customer_information_hash = {}

      document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
        if element.inner_text.match(/ODDIEL\s+I\W/)
          customer_information = element.next_sibling.next_sibling
          customer_information_hash[:customer_name] = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']/span[1]").inner_text.strip
          customer_information_hash[:customer_ico] = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']/span[3]").inner_text.strip

          break
        end
      end
      customer_information_hash
    end

    def contract_information(document)
      contract_information_hash = {}

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
      contract_information_hash
    end

    def suppliers_information(document)
      suppliers = []

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

    # Fix old source urls

    def self.update_old_source_urls
      all_procurements_hash = all_procurements
      Staging::StaProcurement.where("source_url LIKE ?", 'http://www.e-vestnik.sk/EVestnik/Detail/%').each do |sta_procurement|
        self.update_source_url_and_document_id sta_procurement, all_procurements_hash
      end
    end

    def self.update_source_url_and_document_id(sta_procurement, all_procurements_hash)
      key = "#{sta_procurement.bulletin_id}/#{sta_procurement.year}"
      url = all_procurements_hash[key]

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

    def self.all_procurements
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
