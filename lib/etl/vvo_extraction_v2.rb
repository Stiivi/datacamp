# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class VvoExtractionV2
    include Etl::Shared::VvoIncludes

    # -- helper for parsing --

    # notice_result
    # contract_info
    def self.parse_all_downloaded_documents_for_type(dataset_type)
      ids = Dir.glob("data/#{Rails.env}/vvo/procurements/*/*.html").map { |n| File.basename(n, ".html").to_i }
      ids.each_with_index do |document_id, index|
        ext = Etl::VvoExtractionV2.new(document_id)
        if ext.dataset_type == dataset_type
          begin
            ext.digest
          rescue
            puts document_id # exceptions, errors
          end
        end
        if index % 1000 == 0
          puts "#{index} / #{ids.size}"
        end
      end
      nil
    end

    def self.save_all_downloaded_documents
      ids = Dir.glob("data/#{Rails.env}/vvo/procurements/*/*.html").map { |n| File.basename(n, ".html").to_i }
      puts "Downloaded documents: #{ids.count}"
      ids.each do |document_id|
        Delayed::Job.enqueue Etl::VvoExtractionV2.new(document_id)
      end
      nil
    end

    # -- base --

    attr_reader :document_id

    def initialize(document_id)
      @document_id = document_id
    end

    def document_url
      "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{document_id}"
    end

    def document
      return @document if @document
      html = download
      html.gsub!("&nbsp;", " ")
      @document = Nokogiri::HTML(html).xpath("//div[@class='oznamenie']")
    end

    def download
      filename = get_path("vvo/procurements/#{document_id}.html")
      if File.exist?(filename)
        f = File.open(filename)
        html = f.read
        f.close
        html
      else
        Typhoeus::Request.get(document_url).body
      end
    end


    def document_format
      @document_format ||= if document.xpath("./div[@class='MainHeader'][1]").any?
                             :format1
                           elsif document.xpath("./h2[@class='document_number_and_code'][1]").any?
                             :format2
                           elsif document.any?
                             :other
                           else
                             nil
                           end
    end

    def document_type
      @document_type ||= case document_format
                           when :format1
                             document.xpath("./div[@class='MainHeader'][1]").inner_text.match(/\w+$/)[0]
                           when :format2
                             document.xpath("./h2[@class='document_number_and_code'][1]").inner_text.match(/\w+$/)[0]
                           else
                             nil
                         end
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction_v2')
    end

    def dataset_type
      return nil unless document_type
      if document_type.start_with?('V') || document_type.start_with?('IP')
        :notice
      elsif document_type.start_with?('IZ') || document_type.start_with?('ID')
        :performance
      else
        nil
      end
    end

    def is_acceptable?
      dataset_type.present?
    end

    def perform
      if is_acceptable?
        save
      end

    end

    # -- parser --

    def basic_information
      header = document.xpath("//div[@class='oznamenie']")

      procurement_code = bulletin_code = year = published_on = procurement_type = nil

      case document_format
        when :format1
          procurement_code = header.xpath("./div[@class='MainHeader'][1]").inner_text
          bulletin_and_year = header.xpath('./div[2]').inner_text.gsub(/ /, '').match(/Vestník.*?(\d*)\/(\d*)-(\S*)/u) || header.xpath('./div[3]').inner_text.gsub(/ /, '').match(/Vestník.*?(\d*)\/(\d*)-(\S*)/u)
        when :format2
          procurement_code = document.xpath("//div[@class='oznamenie']/./h2[@class='document_number_and_code'][1]").inner_text
          bulletin_and_year = header.xpath("./div[@class='vestnik_number_and_date']").inner_text.gsub(/ /, '').match(/Vestník.*?(\d*)\/(\d*)-(\S*)/u)
        else
          bulletin_and_year = nil
      end

      unless bulletin_and_year.nil?
        bulletin_code = bulletin_and_year[1]
        year = bulletin_and_year[2]
        procurement_type = procurement_code[-3..-1] if procurement_code.size > 3
        published_on = Date.parse(bulletin_and_year[3]) rescue nil
      end

      {
          procurement_code: procurement_code, bulletin_code: bulletin_code.to_i, year: year.to_i,
          procurement_type: procurement_type, published_on: published_on
      }
    end

    # project_type, procedure_type
    def header_procedure_and_project_information
      header_procedure_and_project_information_hash = {}
      main_element = document.xpath("//div[@class='oznamenie']")

      case document_format
        when :format1
          category_element = main_element.xpath("./div[@class='categoryname']").first
          addition_element = (category_element) ? category_element.next : nil
          while addition_element
            if addition_element.xpath(".//strong").inner_text.match(/Druh postupu/)
              procedure_type_element = addition_element.children[1]
              if procedure_type_element
                header_procedure_and_project_information_hash[:procedure_type] = procedure_type_element.inner_text
              end
            elsif addition_element.xpath(".//strong").inner_text.match(/Druh zákazky/)
              project_type_element = addition_element.children[1]
              if project_type_element
                header_procedure_and_project_information_hash[:project_type] = project_type_element.inner_text
              end
            end
            addition_element = addition_element.next_sibling
          end
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/INFORMÁCIA O PLNENÍ ZMLUVY/)
              element.parent.xpath(".//div").each do |div_element|
                if div_element.inner_text.match(/Druh zákazky/)
                  header_procedure_and_project_information_hash[:project_type] = div_element.xpath(".//span[1]").inner_text.strip
                end
              end
            end
          end
        when :format2
          addition_element = document.xpath("//table[@class='mainTable']//tr")[4]
          addition_element.xpath(".//td[@class='cast']//table//td").each do |tr|
            if tr.inner_text.match(/Druh zákazky/)
              header_procedure_and_project_information_hash[:project_type] = strip_last_point(tr.xpath(".//span[@class='hodnota']").inner_text.strip)
            elsif tr.inner_text.match(/Druh postupu/)
              header_procedure_and_project_information_hash[:procedure_type] = strip_last_point(tr.xpath(".//span[@class='hodnota']").inner_text.strip)
            end
          end
        else
      end

      header_procedure_and_project_information_hash
    end

    def customer_information
      customer_information_hash = {}

      case document_format
        when :format1
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+I\W/)
              customer_information = next_element(element.next_sibling)
              customer_information_hash[:customer_name] = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']/span[1]").inner_text.strip
              customer_information_hash[:customer_organisation_code] = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']/span[3]").inner_text.strip
              full_address = customer_information.xpath(".//div[@class='ContactSelectList']/span[@class='titleValue']").children.last.inner_text.strip
              address, zip, place = parse_address(full_address)
              customer_information_hash[:customer_address] = address
              customer_information_hash[:customer_zip] = zip
              customer_information_hash[:customer_place] = place
              customer_information_hash[:customer_country] = customer_information.xpath(".//div[@class='ContactSelectList'][1]/span[2]").inner_text.strip
              customer_information.xpath(".//div[@class='ContactSelectList'][1]/span").each do |span|
                if span.inner_text.strip.start_with?('Kontaktná osoba')
                  customer_information_hash[:customer_contact_persons] = span.next_sibling.next_sibling.inner_text.strip
                elsif span.inner_text.strip.start_with?('Telefón')
                  customer_information_hash[:customer_phone] = span.next_sibling.next_sibling.inner_text.strip
                elsif span.inner_text.strip.start_with?('Fax')
                  customer_information_hash[:customer_fax] = span.next_sibling.next_sibling.inner_text.strip
                elsif span.inner_text.strip.start_with?('Email')
                  customer_information_hash[:customer_email] = span.next_sibling.next_sibling.inner_text.strip
                elsif span.inner_text.strip.start_with?('Mobil')
                  customer_information_hash[:customer_mobile] = span.next_sibling.next_sibling.inner_text.strip
                end
              end
              customer_information.xpath(".//div[@class='subtitle']").each do |div|
                # customer type
                if div.inner_text.strip.match(/Druh verejného obstarávateľa/)
                  customer_information_hash[:customer_type] = div.next_sibling.next_sibling.inner_text.strip
                elsif div.inner_text.strip.match(/DRUH VEREJNÉHO OBSTARÁVATEĽA/)
                  customer_information_hash[:customer_type] = div.next_sibling.next_sibling.xpath(".//span[2]").inner_text.strip
                end
                # customer main activity
                if div.inner_text.strip.match(/Hlavný predmet alebo predmety činnosti/)
                  customer_information_hash[:customer_main_activity] = div.next_sibling.next_sibling.inner_text.strip
                elsif div.inner_text.strip.match(/Hlavná činnosť/)
                  customer_information_hash[:customer_main_activity] = div.next_sibling.next_sibling.inner_text.strip
                elsif div.inner_text.strip.match(/HLAVNÁ ČINNOSŤ/)
                  customer_information_hash[:customer_main_activity] = div.next_sibling.next_sibling.inner_text.strip
                end
                # customer main activity
                if div.inner_text.strip.match(/ZADANIE ZÁKAZKY V MENE INÝCH VEREJNÝCH OBSTARÁVATEĽOV/)
                  customer_information_hash[:customer_purchase_for_others] = !div.next_sibling.next_sibling.inner_text.strip.match(/Nie/)
                elsif div.inner_text.strip.match(/Verejný obstarávateľ nakupuje pre iných verejných obstarávateľov/)
                  customer_information_hash[:customer_purchase_for_others] = !div.next_sibling.next_sibling.inner_text.strip.match(/Nie/)
                elsif div.inner_text.strip.match(/Zadanie zákazky v mene iných obstarávateľov/)
                  customer_information_hash[:customer_purchase_for_others] = !div.next_sibling.next_sibling.inner_text.strip.match(/Obstarávateľ nakupuje v mene iných verejných obstarávateľov/)
                end
              end

              break
            end
          end
        when :format2
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+I\W/)
              customer_information = element.xpath(".//table")[0].xpath(".//tr[2]//table[1]//td[@class='hodnota']")
              customer_information_hash[:customer_name] = customer_information[0].xpath(".//span[@class='hodnota']").inner_text
              customer_information_hash[:customer_organisation_code] = customer_information[1].xpath(".//span[@class='hodnota']").inner_text

              if customer_information[2].inner_text.match(/Poštová adresa/)
                customer_information_hash[:customer_address] = customer_information[2].xpath(".//span[@class='hodnota']").inner_text
                customer_information_hash[:customer_zip] = customer_information[3].xpath(".//span[@class='hodnota']").inner_text
                customer_information_hash[:customer_place] = customer_information[4].xpath(".//span[@class='hodnota']").inner_text
                customer_information_hash[:customer_country] = customer_information[5].xpath(".//span[@class='hodnota']").inner_text
              else
                full_address = customer_information[2].xpath(".//span[@class='hodnota']").inner_text
                address, zip, place = parse_address(full_address)
                customer_information_hash[:customer_address] = address
                customer_information_hash[:customer_zip] = zip
                customer_information_hash[:customer_place] = place
                customer_information_hash[:customer_country] = customer_information[3].xpath(".//span[@class='hodnota']").inner_text
              end

              customer_information.each do |td|
                header = td.children.first.inner_text.strip
                content = td.xpath(".//span[@class='hodnota']").inner_text.strip
                if header.match(/Kontaktná osoba/)
                  customer_information_hash[:customer_contact_persons] = content
                elsif header.match(/Telefón/)
                  customer_information_hash[:customer_phone] = content
                elsif header.match(/Fax/)
                  customer_information_hash[:customer_fax] = content
                elsif header.match(/E-mail/)
                  customer_information_hash[:customer_email] = content
                elsif header.match(/Mobil/)
                  customer_information_hash[:customer_mobile] = content
                end
              end

              element.xpath(".//table")[0].xpath(".//tr").each do |tr|
                header1 = tr.xpath(".//td[2]//span[@class='nazov'][1]").inner_text.strip
                header2 = tr.xpath(".//td[2]//span[@class='podnazov'][1]").inner_text.strip
                content = tr.xpath(".//td[2]//span[@class='hodnota']").inner_text.strip
                if header1.match(/Druh verejného obstarávateľa/) || header2.match(/Druh verejného obstarávateľa/)
                  customer_information_hash[:customer_type] = content
                elsif header1.match(/Hlavný predmet alebo predmety činnosti/) || header1.match(/HLAVNÁ ČINNOSŤ ALEBO ČINNOSTI OBSTARÁVATEĽA/)
                  if content.blank?
                    activities = []
                    next_tr = tr.next_sibling
                    while next_tr && next_tr.xpath(".//td[@class='kod']").inner_text.blank?
                      activities << next_tr.inner_text.strip
                      next_tr = next_tr.next_sibling
                    end
                    content = activities.join(', ')
                  end
                  customer_information_hash[:customer_main_activity] = content if content.present? && customer_information_hash[:customer_main_activity].blank?
                elsif header2.match(/Hlavný predmet alebo predmety činnosti/)
                  activities = [tr.xpath(".//td[2]//table[1]").inner_text]
                  next_tr = tr.next_sibling
                  while next_tr && (next_tr.inner_text.strip.match(/Verejný obstarávateľ nakupuje/).nil? && next_tr.xpath(".//td[@class='kod']").inner_text.blank?)
                    content = next_tr.inner_text.strip
                    activities << content if content.present?
                    next_tr = next_tr.next_sibling
                  end
                  customer_information_hash[:customer_main_activity] = activities.join(', ')
                elsif header1.match(/Verejný obstarávateľ nakupuje/) || header2.match(/Verejný obstarávateľ nakupuje/)
                  customer_information_hash[:customer_purchase_for_others] = !content.match(/Nie/)
                end
              end

              break
            end
          end
        else
      end

      customer_information_hash
    end

    def contract_information
      contract_information_hash = {}

      case document_format
        when :format1
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+II\W/)
              contract_information = element.next_sibling.next_sibling
              contract_information.xpath(".//span[@class='code']").each do |code|
                code_text = code.inner_text.strip
                header_text = code.parent.xpath(".//span[@class='title']").inner_text

                if code_text.match(/^II.1.1/)
                  # nazov
                  contract_information_hash[:project_name] = next_element(code.parent).inner_text.strip

                elsif code_text.match(/^II.1.2/) && header_text.match(/Druh zákazky/)
                  # druh zakazky - project type
                  type_element = next_element(code.parent)

                  first_line_category = false # oznacime, ze na prvom riadku nespomina kategoriu
                  # 237455, 238166
                  if type_element.inner_text.match(/Kategória služby číslo/)
                    contract_information_hash[:project_type] = type_element.xpath(".//span[1]").inner_text.strip
                    first_line_category = true # specialny pripad ked na prvom riadku spomina kategoriu
                  else
                    contract_information_hash[:project_type] = type_element.inner_text.strip
                  end

                  # kategoria
                  place_is_next = false # oznacenie, ze miesto vykonania je hned dalsie
                  if first_line_category
                    # 238166
                    if type_element.next_sibling.next_sibling.inner_text.match(/Kategória služby číslo/)
                      category_element = type_element.next_sibling.next_sibling
                      contract_information_hash[:project_category] = category_element.xpath(".//span[2]").inner_text.strip
                    else #237455
                      category_element = type_element
                    end
                  else
                    category_element = type_element.next_sibling
                    if category_element.inner_text.strip.blank?
                      category_element = category_element.next_sibling
                    end
                    if type_element.inner_text.match(/Tovary/) && category_element.inner_text.match(/Tovary/)
                      category_element = next_element(category_element)
                      place_is_next = true
                    end
                    content = category_element.inner_text.strip
                    if category_element.inner_text.match(/Kategórie služieb sú uvedené v prílohe C1/)
                      content = category_element.xpath(".//span[2]").inner_text.strip
                    elsif category_element.inner_text.match(/Kategória služby číslo/)
                      category_element = next_element(category_element)
                      content = category_element.xpath(".//span[2]").inner_text.strip
                    end
                    contract_information_hash[:project_category] = content
                  end

                  # miesto vykonavania
                  if place_is_next
                    place_element = category_element.next_sibling
                  else
                    place_element = category_element.next_sibling
                    if place_element.inner_text.strip.blank?
                      place_element = place_element.next_sibling
                    end
                  end

                  # 185547
                  if place_element.inner_text.match(/V prípade zmluvy/)
                    place_element = next_element(place_element)
                  end
                  header1 = place_element.xpath(".//span[1]").inner_text
                  header2 = place_element.inner_text
                  if header1.match(/miesto/) || header1.match(/stavenisko/) || header1.match(/lokalita/)
                    contract_information_hash[:place_of_performance] = place_element.xpath(".//span[2]").inner_text.strip
                  elsif header2.match(/miesto/) || header2.match(/lokalita/)
                    contract_information_hash[:place_of_performance] = place_element.xpath(".//span[1]").inner_text.strip
                  end

                  # Nuts code
                  nuts_element = next_element(place_element)
                  if nuts_element.inner_text.match(/NUTS/)
                    if nuts_element.xpath(".//div").any?
                      contract_information_hash[:nuts_code] = nuts_element.xpath(".//div").inner_text
                    else
                      contract_information_hash[:nuts_code] = next_element(nuts_element).inner_text.strip
                    end
                  end

                elsif code_text.match(/^II.1.3/) && header_text.match(/Informácie o rámcovej dohode/)
                  general_contract = code.parent.next_sibling.next_sibling.inner_text.strip
                  contract_information_hash[:general_contract] = (general_contract == "Oznámenie zahŕňa uzavretie rámcovej dohody")

                elsif code_text.match(/^II.1.3/) && header_text.match(/Oznámenie zahŕňa/)
                  general_contract = next_element(code.parent).inner_text.strip
                  contract_information_hash[:general_contract] = (general_contract == "Uzatvorenie rámcovej dohody")

                elsif code_text.match(/^II.1.2/) && header_text.match(/Stručný opis/) #187656
                  contract_information_hash[:project_description] = next_element(code.parent).inner_text.strip

                elsif code_text.match(/^II.1.4/) && header_text.match(/Stručný opis/)
                  contract_information_hash[:project_description] = next_element(code.parent).inner_text.strip

                elsif (code_text.match(/^II.1.3/) || code_text.match(/^II.1.5/)) && (header_text.match(/Spoločný slovník obstarávania/) || header_text.match(/CPV/))
                  dictionary_element = code.parent.next_sibling.next_sibling
                  # TODO move duplicate code to method - spliting subjects
                  dictionary_main_subjects = dictionary_element.xpath(".//div[1]//span[2]").inner_text.match(/Hlavný slovník: (.*)/)
                  if dictionary_main_subjects && dictionary_main_subjects.size > 1
                    contract_information_hash[:dictionary_main_subjects] = dictionary_main_subjects[1].strip
                  end
                  if dictionary_element.xpath(".//div[2]").inner_text.match(/Doplňujúce predmety/) && dictionary_element.xpath(".//div[3]").any?
                    dictionary_additional_subjects = dictionary_element.xpath(".//div[3]").inner_text.match(/Hlavný slovník: (.*)/)
                    if dictionary_additional_subjects && dictionary_additional_subjects.size > 1
                      contract_information_hash[:dictionary_additional_subjects] = dictionary_additional_subjects[1].strip
                    end
                  end

                elsif code_text.match(/^II.1.6/) && (header_text.match(/Informácie o rámcovej dohode/) || header_text.match(/GPA/))
                  gpa_agreement = code.parent.next_sibling.next_sibling.xpath(".//span")
                  contract_information_hash[:gpa_agreement] = !gpa_agreement.inner_text.match(/Nie/)

                end

              end
            end
          end
        when :format2
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+II\W/)
              element.xpath(".//table")[0].xpath(".//tr").each do |tr|
                code_text = tr.xpath(".//td[@class='kod']").inner_text.strip
                header_text = tr.xpath(".//td[2]//span[@class='nazov']").inner_text.strip

                if code_text.match(/^II.1.1/) && header_text.match(/Názov/)
                  name_element = tr
                  if name_element.xpath(".//td[2]//span[@class='hodnota']").empty?
                    name_element = tr.next
                  end
                  name_element = name_element.xpath(".//td[2]//span[@class='hodnota']")
                  contract_information_hash[:project_name] = strip_last_point(name_element.inner_text.strip)

                elsif code_text.match(/^II.1.2/) && header_text.match(/Druh zákazky/)
                  # Typ projektu
                  tr_type_element = tr
                  type_element = tr_type_element.xpath(".//span[@class='hodnota']")
                  if type_element.empty?
                    tr_type_element = next_element(tr_type_element)
                    type_element = tr_type_element.xpath(".//span[@class='hodnota']")
                  end
                  project_type = type_element.inner_text.strip
                  project_type_matches = project_type.match(/(a|b|c)\) (.*)$/)
                  if project_type_matches
                    project_type = project_type_matches[2]
                  end
                  project_type = strip_last_point(project_type)

                  project_type_exceptions = {
                      "Uskutočnenie prác" => 'Práce', #124203
                      "Kúpa" => 'Tovary', # 125359
                      "Vypracovanie projektovej dokumentácie a uskutočnenie prác" => 'Práce',
                      "Projektovanie a uskutočnenie prác" => 'Práce',
                      "Vykonanie" => 'Práce'
                  }

                  # try konvert to number - servies
                  category_number = Integer(project_type) rescue nil
                  if project_type_exceptions.include?(project_type)
                    contract_information_hash[:project_type] = project_type_exceptions[project_type]
                    contract_information_hash[:project_category] = project_type
                    tr_category_element = tr_type_element
                  elsif category_number
                    contract_information_hash[:project_type] = 'Služby'
                    contract_information_hash[:project_category] = project_type
                    tr_category_element = tr_type_element
                  else
                    contract_information_hash[:project_type] = project_type

                    # Kategoria
                    tr_category_element = next_element(tr_type_element)
                    category_element = tr_category_element.xpath(".//span[@class='hodnota']")
                    category = category_element.inner_text.strip
                    contract_information_hash[:project_category] = strip_last_point(category)
                  end

                  # Miesto vykonavania
                  tr_place_element = next_element(tr_category_element)
                  # Continue
                  next unless tr_place_element
                  place_header = tr_place_element.xpath(".//span[@class='podnazov']").inner_text
                  if place_header.match(/V prípade zmluvy/)
                    tr_place_element = next_element(tr_place_element)
                    place_header = tr_place_element.xpath(".//span[@class='podnazov']").inner_text
                  end
                  if place_header.match(/miesto/) || place_header.match(/stavenisko/)
                    contract_information_hash[:place_of_performance] = strip_last_point(tr_place_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                  end

                  # Nuts kod
                  tr_nuts_element = next_element(tr_place_element)
                  # Continue
                  next unless tr_nuts_element
                  nuts_header = tr_nuts_element.xpath(".//span[@class='podnazov']").inner_text
                  if nuts_header.match(/NUTS/)
                    tr_nuts_content_element = next_element(tr_nuts_element)
                    nuts_code = tr_nuts_content_element.xpath(".//span[@class='hodnota']").inner_text.strip
                    contract_information_hash[:nuts_code] = strip_last_point(nuts_code)
                  end

                elsif code_text.match(/^II.1.3/) && header_text.match(/Oznámenie zahŕňa/)
                  tr_general_contract = tr
                  if tr_general_contract.xpath(".//td[2]//span[@class='hodnota']").empty?
                    tr_general_contract = tr.next
                  end
                  general_contract_element = tr_general_contract.xpath(".//td[2]//span[@class='hodnota']")
                  general_contract = strip_last_point(general_contract_element.inner_text.strip)
                  contract_information_hash[:general_contract] = (general_contract == "Uzatvorenie rámcovej dohody")

                elsif (code_text.match(/^II.1.4/) || code_text.match(/^II.1.2/)) && header_text.match(/Stručný opis/)
                  tr_project_description = tr
                  # TODO refactor - move to method
                  if tr_project_description.xpath(".//td[2]//span[@class='hodnota']").empty?
                    tr_project_description = tr.next
                  end
                  project_description_element = tr_project_description.xpath(".//td[2]//span[@class='hodnota']")
                  contract_information_hash[:project_description] = project_description_element.inner_text.strip

                elsif (code_text.match(/^II.1.5/) || code_text.match(/^II.1.3/)) && (header_text.match(/Spoločný slovník obstarávania/) || header_text.match(/CPV/))
                  tr_subjects = tr
                  if tr_subjects.xpath(".//td[2]//span[@class='hodnota']").empty?
                    tr_subjects = tr.next
                  end
                  subjects = tr_subjects.xpath(".//td[2]//span[@class='hodnota']")
                  dictionary_main_subjects = subjects[2].inner_text.strip
                  contract_information_hash[:dictionary_main_subjects] = strip_last_point(dictionary_main_subjects)

                  if subjects.size == 5
                    next_dictionary_main_subjects = strip_last_point(subjects[4].inner_text.strip)
                    contract_information_hash[:dictionary_main_subjects]+= ', ' + next_dictionary_main_subjects if next_dictionary_main_subjects.present?
                  end

                  tr_additional_subjects = next_element(tr_subjects)
                  next unless tr_additional_subjects
                  additional_subjects_element = tr_additional_subjects.xpath(".//td[2]//span[@class='hodnota']")
                  if additional_subjects_element.inner_text.match(/Doplňujúce predmety/)
                    dictionary_additional_subjects = additional_subjects_element.children[-2].inner_text.strip
                    # TODO Refactor move to method
                    dictionary_additional_subjects = dictionary_additional_subjects.match(/Hlavný slovník: (.*)/)
                    if dictionary_additional_subjects && dictionary_additional_subjects.size > 1
                      contract_information_hash[:dictionary_additional_subjects] = strip_last_point(dictionary_additional_subjects[1].strip)
                    end
                  end

                elsif code_text.match(/^II.1.6/) && (header_text.match(/Dohoda o vládnom obstarávaní/) || header_text.match(/GPA/))
                  # TODO move to method - as next_tr_content ??
                  tr_gpa_agreement = tr
                  if tr_gpa_agreement.xpath(".//td[2]//span[@class='hodnota']").empty?
                    tr_gpa_agreement = tr.next
                  end
                  gpa_agreement = tr_gpa_agreement.xpath(".//td[2]//span[@class='hodnota']").inner_text.strip
                  contract_information_hash[:gpa_agreement] = !gpa_agreement.match(/Nie/)

                end

              end
            end
          end
        else
      end

      contract_information_hash
    end

    def procedure_information
      procedure_information_hash = {}

      case document_format
        when :format1
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+IV\W/)
              procedure_information_element = element.next_sibling.next_sibling
              procedure_information_element.xpath(".//span[@class='code']").each do |code|
                code_text = code.inner_text.strip
                header_text = code.parent.xpath(".//span[@class='title']").inner_text

                if code_text.match(/^IV.1.1/) && header_text.match(/Druh postupu/)
                  procedure_type_element = next_element(code.parent).xpath(".//span")
                  procedure_information_hash[:procedure_type] = procedure_type_element.inner_text.strip

                elsif code_text.match(/^IV.2.1/) && header_text.match(/Kritériá na vyhodnotenie ponúk/)
                  first_criteria_element = next_element(code.parent)
                  criteria_element = first_criteria_element.xpath(".//span")
                  procedure_offers_criteria = criteria_element.inner_text.strip
                  if procedure_offers_criteria.match(/ponuka z hľadiska/)
                    next_criteria_element = first_criteria_element.next_sibling
                    while next_criteria_element && next_criteria_element.xpath(".//span[@class='code']").empty?
                      if next_criteria_element.inner_text.strip.present?
                        procedure_offers_criteria+= ', ' + next_criteria_element.inner_text.strip
                      end
                      next_criteria_element = next_criteria_element.next_sibling
                    end
                  end
                  procedure_information_hash[:procedure_offers_criteria] = procedure_offers_criteria

                elsif code_text.match(/^IV.2.2/) && (header_text.match(/Využila sa elektronická aukcia/) || header_text.match(/Informácia o elektronickej aukcii/))
                  auction_element = next_element(code.parent).xpath(".//span")
                  procedure_information_hash[:procedure_use_auction] = auction_element.inner_text.strip.match(/Áno/).present?

                elsif code_text.match(/^IV.3.2/) && header_text.match(/Predchádzajúce/) && (header_text.match(/oznámenia/) || header_text.match(/oznámenie/))
                  previous_element = next_element(code.parent)
                  previous_status_element = previous_element.xpath(".//span")
                  previous_status = previous_status_element.inner_text.strip

                  # set nil for all attributes
                  number_attributes = [:previous_notification1_number, :previous_notification2_number, :previous_notification3_number]
                  published_on_attributes = [:previous_notification1_published_on, :previous_notification2_published_on, :previous_notification3_published_on]
                  3.times.each do |index|
                    procedure_information_hash[number_attributes[index]] = nil
                    procedure_information_hash[published_on_attributes[index]] = nil
                  end

                  if previous_status.match(/Áno/)

                    previous_notification_element = next_element(previous_element)
                    next_index = 0
                    while previous_notification_element && previous_notification_element.xpath(".//span[@class='code']").empty?
                      if previous_notification_element.inner_text.match(/Číslo oznámenia/)
                        number = previous_notification_element.xpath(".//span").inner_text
                        published_on = nil
                        if number.present?
                          date_element = previous_notification_element.next_sibling
                          published_on = parse_date(date_element.inner_text)
                        else
                          number_and_date = previous_notification_element.inner_text.strip
                          matches = number_and_date.match(/Číslo oznámenia vo VVO\: (.*) z(.*)/)
                          if matches.size == 3
                            number = matches[1]
                            published_on = parse_date(matches[2].strip)
                          end
                        end
                        # set attributes
                        number = number.gsub(" číslo", "") if number
                        procedure_information_hash[number_attributes[next_index]] = number
                        procedure_information_hash[published_on_attributes[next_index]] = published_on
                        next_index+= 1
                      end
                      previous_notification_element = next_element(previous_notification_element)
                    end

                  end

                end
              end
            end
          end
        when :format2
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+IV\W/)
              element.xpath(".//table")[0].xpath(".//tr").each do |tr|
                code_text = tr.xpath(".//td[@class='kod']").inner_text.strip
                header_text = tr.xpath(".//td[2]//span[@class='nazov']").inner_text.strip

                if code_text.match(/^IV.1.1/) && header_text.match(/Druh postupu/)
                  procedure_type_element = tr.xpath(".//td[2]//span[@class='hodnota']")
                  if procedure_type_element.any?
                    procedure_information_hash[:procedure_type] = strip_last_point(procedure_type_element.inner_text.strip)
                  end

                elsif code_text.match(/^IV.2.1/) && header_text.match(/Kritériá na vyhodnotenie ponúk/)
                  tr_first_criteria_element = tr
                  first_criteria_element = tr_first_criteria_element.xpath(".//td[2]//span[@class='hodnota']")
                  if first_criteria_element.any?
                    procedure_offers_criteria = strip_last_point(first_criteria_element.inner_text.strip)
                    next_criteria_element = tr_first_criteria_element.next_sibling
                    while next_criteria_element && next_criteria_element.xpath(".//td[@class='kod']").inner_text.blank?
                      if next_criteria_element.inner_text.strip.present?
                        procedure_offers_criteria+= ', ' + next_criteria_element.inner_text.strip
                      end
                      next_criteria_element = next_criteria_element.next_sibling
                    end
                    procedure_information_hash[:procedure_offers_criteria] = procedure_offers_criteria
                  end

                elsif code_text.match(/^IV.2.2/) && header_text.match(/Využila sa elektronická aukcia/)
                  auction_element = tr.xpath(".//td[2]//span[@class='hodnota']")
                  procedure_information_hash[:procedure_use_auction] = auction_element.inner_text.strip.match(/Áno/).present?

                elsif code_text.match(/^IV.3.2/) && header_text.match(/Predchádzajúce oznámenie/)
                  tr_previous_element = tr
                  previous_status_element = tr_previous_element.xpath(".//span[@class='hodnota']")
                  previous_status = previous_status_element.inner_text.strip

                  # set nil for all attributes
                  number_attributes = [:previous_notification1_number, :previous_notification2_number, :previous_notification3_number]
                  published_on_attributes = [:previous_notification1_published_on, :previous_notification2_published_on, :previous_notification3_published_on]
                  3.times.each do |index|
                    procedure_information_hash[number_attributes[index]] = nil
                    procedure_information_hash[published_on_attributes[index]] = nil
                  end

                  if previous_status.match(/Áno/)

                    previous_notification_element = tr_previous_element.next_sibling
                    next_index = 0
                    while previous_notification_element && previous_notification_element.xpath(".//td[@class='kod']").inner_text.blank?
                      if previous_notification_element.inner_text.match(/Číslo oznámenia/)
                        number_and_date = previous_notification_element.xpath(".//span[@class='hodnota']").inner_text
                        matches = number_and_date.match(/(.*) z (.*)/)
                        if matches.size == 3
                          number = matches[1]
                          published_on = parse_date(matches[2])
                        else
                          number = number_and_date
                          published_on = nil
                        end
                        # set attributes
                        number = number.gsub(" číslo", "") if number
                        number = number.gsub(": ", "") if number.start_with?(": ")
                        procedure_information_hash[number_attributes[next_index]] = number
                        procedure_information_hash[published_on_attributes[next_index]] = published_on
                        next_index+= 1
                      end
                      previous_notification_element = next_element(previous_notification_element)
                    end

                  end

                end
              end
            end
          end
        else
      end

      procedure_information_hash
    end

    # Suppliers information
    # Only for notice_result

    def suppliers_information
      suppliers = []

      case document_format
        when :format1
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+V\W/)
              supplier_information = element.next_sibling.next_sibling
              supplier_hash = {}
              supplier_information.xpath(".//span[@class='code']").each do |code|
                code_text = code.inner_text.strip
                header_text = code.parent.xpath(".//span[@class='title']").inner_text

                if code_text.match(/V\.*.*?[^\d]1[^\d]$/) && (header_text.match(/Dátum/) || header_text.match(/DÁTUM/))

                  # add non empty to array
                  if supplier_hash.any?
                    suppliers << supplier_hash if supplier_hash[:supplier_name]
                    supplier_hash = {}
                  end

                  contract_name_element = code.parent.previous_sibling.previous_sibling
                  if contract_name_element.name == "div" && contract_name_element.attributes["class"].value == "textArea"
                    supplier_hash[:contract_name] = contract_name_element.xpath(".//span[2]").inner_text.strip
                  end

                  contract_date_element = next_element(code.parent)
                  supplier_hash[:contract_date] = parse_date(contract_date_element.inner_text)

                elsif code_text.match(/V\.*.*?[^\d]2[^\d]$/) && (header_text.match(/Počet predložených ponúk/) || header_text.match(/Počet uchádzačov, ktorí predložili ponuku/))
                  offers_total_count_element = next_element(code.parent)
                  supplier_hash[:offers_total_count] = offers_total_count_element.inner_text.strip.to_i

                elsif code_text.match(/V\.*.*?[^\d]3[^\d]$/) && header_text.match(/Počet vylúčených uchádzačov alebo záujemcov/)
                  offers_excluded_count_element = next_element(code.parent)
                  supplier_hash[:offers_excluded_count] = offers_excluded_count_element.inner_text.strip.to_i

                elsif code_text.match(/V\.*.*?[^\d]2[^\d]$/) && (header_text.match(/INFORMÁCIA O PONUKÁCH/) || header_text.match(/Informácie o ponukách/))
                  offers_count_element = next_element(code.parent)
                  while offers_count_element && offers_count_element.xpath(".//span[@class='code']").empty?
                    if offers_count_element.inner_text.match(/Počet prijatých ponúk/)
                      supplier_hash[:offers_total_count] = offers_count_element.xpath(".//span").inner_text.to_i
                    elsif offers_count_element.inner_text.match(/Počet ponúk prijatých elektronickou cestou/)
                      supplier_hash[:offers_online_count] = offers_count_element.xpath(".//span").inner_text.to_i
                    end
                    offers_count_element = next_element(offers_count_element)
                  end

                elsif (code_text.match(/V\.*.*?[^\d]3[^\d]$/) || code_text.match(/V\.*.*?[^\d]4[^\d]$/)) && (header_text.match(/Názov a adresa/) || header_text.match(/NÁZOV A ADRESA/))
                  supplier_information = next_element(code.parent)
                  supplier_hash[:supplier_name] = supplier_information.xpath("./span[@class='titleValue']/span[1]").inner_text.strip
                  supplier_hash[:supplier_organisation_code] = supplier_information.xpath(".//span[@class='titleValue']/span[3]").inner_text.strip

                  full_address = supplier_information.xpath(".//span[@class='titleValue']").children.last.inner_text.strip
                  address, zip, place = parse_address(full_address)
                  supplier_hash[:supplier_address] = address
                  supplier_hash[:supplier_zip] = zip
                  supplier_hash[:supplier_place] = place
                  address_element = supplier_information.xpath(".//span[@class='titleValue']").first

                  country_element = next_element(address_element)
                  while country_element && country_element.inner_text.strip.blank?
                    country_element = next_element(country_element)
                  end
                  supplier_hash[:supplier_country] = country_element.inner_text.strip if country_element

                  supplier_information.xpath("./span").each do |span|
                    if span.inner_text.strip.start_with?('Telefón')
                      supplier_hash[:supplier_phone] = span.next_sibling.next_sibling.inner_text.strip
                    elsif span.inner_text.strip.start_with?('Fax')
                      supplier_hash[:supplier_fax] = span.next_sibling.next_sibling.inner_text.strip
                    elsif span.inner_text.strip.start_with?('Email')
                      supplier_hash[:supplier_email] = span.next_sibling.next_sibling.inner_text.strip
                    elsif span.inner_text.strip.start_with?('Mobil')
                      supplier_hash[:supplier_mobile] = span.next_sibling.next_sibling.inner_text.strip
                    end
                  end

                elsif (code_text.match(/V\.*.*?[^\d]4[^\d]$/) || code_text.match(/V\.*.*?[^\d]5[^\d]$/)) && (header_text.match(/Informácie o hodnote/) || header_text.match(/INFORMÁCIE O HODNOTE/))
                  price_element = next_element(code.parent)

                  if price_element.inner_text.strip.match(/Hodnota/)
                    price_value_element = price_element
                    price_hash = parse_price1(price_value_element)
                    supplier_hash[:procurement_currency] = price_hash[:currency]
                    supplier_hash[:final_price] = price_hash[:price]
                    supplier_hash[:final_price_vat_included] = price_hash[:price_vat_included]
                    supplier_hash[:final_price_vat_rate] = price_hash[:price_vat_rate]
                    supplier_hash[:final_price_range] = false
                  else
                    while price_element && price_element.xpath(".//span[@class='code']").inner_text.blank?
                      if price_element.inner_text.strip.match(/konečná(.*)hodnota/)
                        price_value_element = next_price_value_element(price_element)
                        price_hash = parse_price1(price_value_element)
                        supplier_hash[:procurement_currency] = price_hash[:currency]
                        if price_hash[:price_range]
                          supplier_hash[:final_price_min] = price_hash[:price_min]
                          supplier_hash[:final_price_max] = price_hash[:price_max]
                          supplier_hash[:final_price_range] = true
                        else
                          supplier_hash[:final_price] = price_hash[:price]
                          supplier_hash[:final_price_range] = false
                        end
                        supplier_hash[:final_price_vat_included] = price_hash[:price_vat_included]
                        supplier_hash[:final_price_vat_rate] = price_hash[:price_vat_rate]
                      elsif price_element.inner_text.strip.match(/predpokladaná(.*)hodnota/)
                        price_value_element = next_price_value_element(price_element)
                        price_hash = parse_price1(price_value_element)
                        supplier_hash[:procurement_currency] = price_hash[:currency]
                        supplier_hash[:draft_price] = price_hash[:price]
                        supplier_hash[:draft_price_vat_included] = price_hash[:price_vat_included]
                        supplier_hash[:draft_price_vat_rate] = price_hash[:price_vat_rate]
                      end
                      price_element = next_element(price_element)
                    end
                  end

                  # Subdodavky
                elsif (code_text.match(/V\.*.*?[^\d]4[^\d]$/) || code_text.match(/V\.*.*?[^\d]5[^\d]$/)) && (header_text.match(/predpoklad subdodávok/) || header_text.match(/subdodávkach/))
                  subcontracted_element = next_element(code.parent)
                  subcontracted = subcontracted_element.xpath(".//span").inner_text.strip
                  supplier_hash[:procurement_subcontracted] = !subcontracted.match(/Nie/)
                end
              end
              # add non empty to array
              if supplier_hash.any?
                suppliers << supplier_hash if supplier_hash[:supplier_name]
                supplier_hash = {}
              end
            end
          end

        when :format2
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+V\W/)
              supplier_hash = {}
              supplier_information_element = element.xpath(".//table[1]//tr[2]//td[2]//table[1]//tr")
              supplier_information_element = element.xpath(".//table[1]//tr[1]//td[1]//table[1]//tr") if supplier_information_element.empty?
              supplier_information_element = element.xpath(".//table[1]//tr[1]//td[2]//table[1]//tr") if supplier_information_element.empty?

              supplier_information_element.each do |tr|
                code_text = tr.xpath(".//td[@class='kod']").inner_text.strip
                header_text = tr.xpath(".//td[2]//span[@class='nazov']").inner_text.strip

                if tr.xpath(".//span[@class='podnazov']") && tr.xpath(".//span[@class='podnazov']").inner_text.match(/(Z|z)mluva k časti/)
                  # add non empty to array
                  if supplier_hash.any?
                    suppliers << supplier_hash if supplier_hash[:supplier_name]
                    supplier_hash = {}
                  end

                  contract_name_element = next_element(tr)
                  if contract_name_element.xpath(".//span[@class='nazov']").inner_text.match(/Názov/) || contract_name_element.xpath(".//span[@class='podnazov']").inner_text.match(/Názov/)
                    supplier_hash[:contract_name] = strip_last_point(contract_name_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                  end

                elsif code_text.match(/V\.*.*?[^\d]1[^\d]$/) && (header_text.match(/Dátum/) || header_text.match(/DÁTUM/))
                  contract_date_element = tr.xpath(".//span[@class='hodnota']")
                  supplier_hash[:contract_date] = parse_date(contract_date_element.inner_text.strip)

                elsif code_text.match(/V\.*.*?[^\d]2[^\d]$/) && (header_text.match(/Počet prijatých/) || header_text.match(/POČET PRIJATÝCH/))
                  supplier_hash[:offers_total_count] = tr.xpath(".//span[@class='hodnota']").inner_text.to_i

                elsif tr.inner_text.strip.match(/V(\.)(\d\.)?3(\D*)$/) && (header_text.match(/Názov/) || header_text.match(/NÁZOV/))

                  supplier_wrapper_element = next_element(tr)
                  supplier_information_element = supplier_wrapper_element.xpath(".//table[1]//td[@class='hodnota']")
                  supplier_hash[:supplier_name] = supplier_information_element[0].xpath(".//span[@class='hodnota']").inner_text

                  organisation_code = parse_organisation_code(supplier_information_element[1].xpath(".//span[@class='hodnota']").inner_text)
                  if organisation_code.blank? || mostly_numbers?(organisation_code)
                    address_index = 2
                  else
                    organisation_code = ""
                    address_index = 1
                  end
                  supplier_hash[:supplier_organisation_code] = organisation_code

                  if supplier_information_element[address_index].inner_text.match(/Poštová adresa/)
                    supplier_hash[:supplier_address] = supplier_information_element[address_index].xpath(".//span[@class='hodnota']").inner_text
                    supplier_hash[:supplier_zip] = parse_zip(supplier_information_element[address_index+1].xpath(".//span[@class='hodnota']").inner_text)
                    supplier_hash[:supplier_place] = supplier_information_element[address_index+2].xpath(".//span[@class='hodnota']").inner_text
                    supplier_hash[:supplier_country] = supplier_information_element[address_index+3].xpath(".//span[@class='hodnota']").inner_text
                  else
                    full_address = supplier_information_element[address_index].xpath(".//span[@class='hodnota']").inner_text
                    address, zip, place = parse_address(full_address)
                    supplier_hash[:supplier_address] = address
                    supplier_hash[:supplier_zip] = zip
                    supplier_hash[:supplier_place] = place
                    supplier_hash[:supplier_country] = supplier_information_element[address_index+1].xpath(".//span[@class='hodnota']").inner_text
                  end

                  supplier_information_element.each do |td|
                    header = td.children.first.inner_text.strip
                    content = td.xpath(".//span[@class='hodnota']").inner_text.strip
                    if header.match(/Telefón/)
                      supplier_hash[:supplier_phone] = content
                    elsif header.match(/Fax/)
                      supplier_hash[:supplier_fax] = content
                    elsif header.match(/E-mail/)
                      supplier_hash[:supplier_email] = content
                    elsif header.match(/Mobil/)
                      supplier_hash[:supplier_mobile] = content
                    end
                  end

                  # prices
                elsif tr.inner_text.strip.match(/V(\.)(\d\.)?4(\D*)$/) && (header_text.match(/Informácie o hodnote/) || header_text.match(/INFORMÁCIE O HODNOTE/))
                  price_element = next_element(tr)

                  while price_element && price_element.xpath(".//td[@class='kod']").inner_text.blank?
                    if price_element.inner_text.strip.match(/konečná(.*)hodnota/)
                      price_value_element = next_price_value_element(price_element)
                      if price_value_element
                        price_hash = parse_price2(price_value_element)
                        supplier_hash[:procurement_currency] = price_hash[:currency]
                        if price_hash[:price_range]
                          supplier_hash[:final_price_min] = price_hash[:price_min]
                          supplier_hash[:final_price_max] = price_hash[:price_max]
                          supplier_hash[:final_price_range] = true
                        else
                          supplier_hash[:final_price] = price_hash[:price]
                          supplier_hash[:final_price_range] = false
                        end
                        supplier_hash[:final_price_vat_included] = price_hash[:price_vat_included]
                        supplier_hash[:final_price_vat_rate] = price_hash[:price_vat_rate]
                      end
                    elsif price_element.inner_text.strip.match(/predpokladaná(.*)hodnota/)
                      price_value_element = next_price_value_element(price_element, [/konečná(.*)hodnota/])
                      if price_value_element
                        price_hash = parse_price2(price_value_element)
                        supplier_hash[:procurement_currency] = price_hash[:currency]
                        supplier_hash[:draft_price] = price_hash[:price]
                        supplier_hash[:draft_price_vat_included] = price_hash[:price_vat_included]
                        supplier_hash[:draft_price_vat_rate] = price_hash[:price_vat_rate]
                      end
                    end
                    price_element = next_element(price_element)
                  end

                elsif code_text.match(/V\.*.*?[^\d]5[^\d]$/) && (header_text.match(/PREDPOKLAD SUBDODÁVOK/) || header_text.match(/predpoklad subdodávok/) || header_text.match(/subdodávkach/))
                  supplier_hash[:procurement_subcontracted] = !tr.xpath(".//span[@class='hodnota']").inner_text.match(/Nie/)

                end
              end
              # add non empty to array
              if supplier_hash.any?
                suppliers << supplier_hash if supplier_hash[:supplier_name]
                supplier_hash = {}
              end
            end
          end
        else
      end

      {:suppliers => suppliers}
    end

    # Additional information
    # Only for notice_result

    def additional_information
      additional_information_hash = {}

      case document_format
        when :format1
          document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
            if element.inner_text.match(/ODDIEL\s+VI\W/)
              addition_information_element = element.next_sibling.next_sibling
              addition_information_element.xpath(".//span[@class='code']").each do |code|
                code_text = code.inner_text.strip
                header_text = code.parent.xpath(".//span[@class='title']").inner_text

                if code_text.match(/VI\.*.*?[^\d]1[^\d]$/) && (header_text.match(/FONDOCH/) ||header_text.match(/financovaného z fondov EÚ/))
                  procurement_euro_found_element = next_element(code.parent)
                  if procurement_euro_found_element.xpath(".//span").any?
                    additional_information_hash[:procurement_euro_found] = !procurement_euro_found_element.xpath(".//span").inner_text.strip.match(/Nie/)
                  end
                elsif code_text.match(/VI\.*.*?[^\d]2[^\d]$/) && (header_text.match(/DOPLŇUJÚCE INFORMÁCIE/) ||header_text.match(/Ďalšie informácie/))
                  additional_information_hash[:evaluation_committee] = parse_committee(next_element(code.parent).inner_text.strip)
                end

              end
            end
          end
        when :format2
          document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
            if element.inner_text.match(/ODDIEL\s+VI\W/)
              element.xpath(".//table")[0].xpath(".//tr").each do |tr|
                code_text = tr.xpath(".//td[@class='kod']").inner_text.strip
                header_text = tr.xpath(".//td[2]//span[@class='nazov']").inner_text.strip

                if code_text.match(/VI\.*.*?[^\d]1[^\d]$/) && (header_text.match(/FINANCOVANÉHO Z FONDOV/) ||header_text.match(/financovaného z fondov EÚ/))
                  additional_information_hash[:procurement_euro_found] = !tr.xpath(".//span[@class='hodnota']").inner_text.match(/Nie/)

                elsif code_text.match(/VI\.*.*?[^\d]2[^\d]$/) && (header_text.match(/ĎALŠIE INFORMÁCIE/) || header_text.match(/DOPLŇUJÚCE INFORMÁCIE/) ||header_text.match(/Ďalšie informácie/))
                  evaluation_committee = parse_committee(tr.xpath(".//span[@class='hodnota']").inner_text.strip, true)
                  additional_information_hash[:evaluation_committee] = evaluation_committee if evaluation_committee
                end

              end
            end
          end

        else

      end
      additional_information_hash
    end

    # Digest - for each dataset_type other

    def digest
      # common
      hashes = [basic_information, header_procedure_and_project_information, customer_information, contract_information]
      case dataset_type
        when :notice
          hashes += [procedure_information, suppliers_information, additional_information]
        when :performance
          # TODO
        else
          hashes = []
      end
      digest_hash = hashes.first
      hashes[1..-1].each do |merge_hash|
        digest_hash.merge!(merge_hash)
      end
      digest_hash
    end


    def digest_attributes
      case dataset_type
        when :notice
          [
              # Basic information
              :procurement_code, :bulletin_code, :year, :procurement_type, :published_on,
              # Customer information
              :customer_name, :customer_organisation_code, :customer_address, :customer_place, :customer_zip, :customer_country,
              :customer_contact_persons, :customer_phone, :customer_mobile, :customer_email, :customer_fax,
              :customer_type, :customer_purchase_for_others, :customer_main_activity,
              # Contract information
              :project_name, :project_type, :project_category, :place_of_performance, :nuts_code, :project_description,
              :general_contract, :dictionary_main_subjects, :dictionary_additional_subjects, :gpa_agreement,
              # Procedure information
              :procedure_type, :procedure_offers_criteria, :procedure_use_auction, :previous_notification1_number, :previous_notification2_number, :previous_notification3_number, :previous_notification1_published_on, :previous_notification2_published_on, :previous_notification3_published_on,
              # Supplier information
              :contract_name, :contract_date, :offers_total_count, :offers_online_count, :offers_excluded_count,
              :supplier_name, :supplier_organisation_code, :supplier_address, :supplier_place, :supplier_zip, :supplier_country,
              :supplier_phone, :supplier_mobile, :supplier_email, :supplier_fax,
              :procurement_currency, :final_price, :final_price_range, :final_price_min, :final_price_max, :final_price_vat_included, :final_price_vat_rate,
              :draft_price, :draft_price_vat_included, :draft_price_vat_rate, :procurement_subcontracted,
              # Additional information
              :procurement_euro_found, :evaluation_committee
          ]
        when :performance
          # TODO
        else
          []
      end
    end

    def save

      procurement_digest = digest

      case dataset_type
        when :notice
          shorten_attributes = [:supplier_name, :customer_name]
          procurement_digest[:suppliers].each_with_index do |supplier_hash, supplier_index|
            procurement_hash = procurement_digest.dup
            procurement_hash.delete(:suppliers)
            procurement_hash.merge!(supplier_hash)

            # Initialize object
            procurement_object = Dataset::DsProcurementV2Notice.find_or_initialize_by_document_id_and_supplier_index(document_id, supplier_index)

            digest_attributes.each do |attribute|
              attribute_value = procurement_hash[attribute]
              # shorten attribute before save
              attribute_value = attribute_value.first(255) if attribute_value && shorten_attributes.include?(attribute)
              procurement_object[attribute] = attribute_value
            end
            procurement_object.document_url = document_url

            # Map customer to regis
            customer_regis_organisation = find_regis_organisation(procurement_hash[:customer_organisation_code])
            if customer_regis_organisation
              procurement_object.customer_organisation_id = customer_regis_organisation.id
              procurement_object.customer_regis_name = customer_regis_organisation.name
            end

            # Map supplier to regis
            supplier_regis_organisation = find_regis_organisation(procurement_hash[:supplier_organisation_code])
            if supplier_regis_organisation
              procurement_object.supplier_organisation_id = supplier_regis_organisation.id
              procurement_object.supplier_regis_name = supplier_regis_organisation.name
            end

            procurement_object.save
          end

        when :performance
          # TODO
        else
      end

    end

    private

    def find_regis_organisation(organisation_code)
      Dataset::DsOrganisation.find_by_ico(organisation_code.to_i)
    end

    def next_price_value_element(element, break_matches = [])
      price_value_element = next_element(element)
      while price_value_element && (!price_value_element.inner_text.strip.match(/^Hodnota/) && !price_value_element.inner_text.strip.match(/^Najnižšia/))
        return if break_matches.any? { |m| price_value_element.inner_text.strip.match(m) }
        price_value_element = next_element(price_value_element)
      end
      price_value_element
    end

    def parse_price1(price_element)
      price_hash = {}
      if price_element.xpath(".//span").size == 1
        price_hash[:price] = parse_float(price_element.xpath(".//span[1]").inner_text.strip)
        price_hash[:price_interval] = false
      elsif price_element.xpath(".//span").size == 2
        price_hash[:price] = parse_float(price_element.xpath(".//span[1]").inner_text.strip)
        price_hash[:currency] = parse_currency(price_element.xpath(".//span[2]").inner_text.strip)
        price_hash[:price_interval] = false
      elsif price_element.xpath(".//span").size == 3
        price_hash[:price_range] = true
        price_hash[:price_min] = parse_float(price_element.xpath(".//span[1]").inner_text.strip)
        price_hash[:price_max] = parse_float(price_element.xpath(".//span[2]").inner_text.strip)
        price_hash[:currency] = parse_currency(price_element.xpath(".//span[3]").inner_text.strip)
      end
      vat_element = next_element(price_element)
      if vat_element.inner_text.match(/Mena/)
        price_hash[:currency] = parse_currency(vat_element.xpath(".//span").inner_text.strip)
        vat_element = next_element(vat_element)
      end
      if vat_element.inner_text.match(/Bez DPH/)
        price_hash[:price_vat_included] = false
      elsif vat_element.inner_text.match(/Vrátane DPH/)
        price_hash[:price_vat_included] = true
        vat_rate_element = next_element(vat_element)
        if vat_rate_element.inner_text.match(/Sadzba DPH/)
          price_hash[:price_vat_rate] = parse_float(vat_rate_element.xpath(".//span").inner_text.strip)
        end
      end
      price_hash
    end

    def parse_price2(price_element)
      price_hash = {}
      price_elements = price_element.xpath(".//span[@class='hodnota']")
      if price_elements.size == 1
        price_hash[:price] = parse_float(price_elements[0].inner_text.strip)
        price_hash[:price_interval] = false
      elsif price_elements.size == 2
        price_hash[:price] = parse_float(price_elements[0].inner_text.strip)
        price_hash[:currency] = parse_currency(price_elements[0].inner_text.strip)
        price_hash[:price_interval] = false
      elsif price_elements.size == 3
        price_hash[:price_range] = true
        price_hash[:price_min] = parse_float(price_elements[0].inner_text.strip)
        price_hash[:price_max] = parse_float(price_elements[1].inner_text.strip)
        price_hash[:currency] = parse_currency(price_elements[2].inner_text.strip)
      end
      vat_element = next_element(price_element)
      if vat_element.inner_text.match(/Mena/) #todo
        price_hash[:currency] = parse_currency(vat_element.xpath(".//span[@class='hodnota']").inner_text.strip)
        vat_element = next_element(vat_element)
      end
      if vat_element.inner_text.match(/Bez DPH/)
        price_hash[:price_vat_included] = false
      elsif vat_element.inner_text.match(/Vrátane DPH/)
        price_hash[:price_vat_included] = true
        vat_rate_element = next_element(vat_element)
        if vat_rate_element.inner_text.match(/Sadzba DPH/)
          price_hash[:price_vat_rate] = parse_float(vat_rate_element.xpath(".//span").last.inner_text.strip)
        end
      end
      price_hash
    end

    def parse_committee(str, match_keyword = false)
      patterns = [/(.*)Komisia na vyhodnocovanie ponúk:(.*)/, /(.*)Zoznam členov komisie, ktorí vyhodnocovali ponuky:(.*)/, /(.*)Ponuku hodnotila komisia v zložení:(.*)/, /(.*)Členovia komisie, ktorí vyhodnocovali ponuky:(.*)/, /(.*)Členovia komisie na vyhodnotenie ponúk s právom vyhodnocovať ponuky:(.*)/, /(.*)Na rokovacie konanie bez zverejnenia bola zriadená komisia v zložení(.*):(.*)/, /(.*)Komisia pracovala v tomto zložení(.*):(.*)/, /(.*)Členmi(.*)hodnotiacej komisie boli(.*):(.*)/, /(.*)komisia:(.*)/, /(.*)ktorí vyhodnocovali ponuky:(.*)/]
      patterns.each do |pattern|
        matches = str.match(pattern)
        if matches
          return matches[-1].strip
        end
      end
      if match_keyword
        (str.match(/komisia/) || str.match(/komisie/)) ? str : nil
      else
        str
      end
    end

  end
end
