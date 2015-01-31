# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module SuppliersInformationParser

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

                  elsif code_text.match(/V\.*.*?[^\d]1[^\d]$/) && (header_text.match(/VÝBER NAJVHODNEJŠIEHO/))
                    # add non empty to array
                    if supplier_hash.any?
                      suppliers << supplier_hash if supplier_hash[:supplier_name]
                      supplier_hash = {}
                    end

                    contract_name_element = code.parent.previous_sibling.previous_sibling
                    if contract_name_element.name == "div" && contract_name_element.attributes["class"].value == "textArea"
                      supplier_hash[:contract_name] = contract_name_element.xpath(".//span[2]").inner_text.strip
                    end

                  elsif code_text.match(/V\.*.*?[^\d]2[^\d]$/) && (header_text.match(/Počet predložených ponúk/) || header_text.match(/Počet uchádzačov, ktorí predložili ponuku/))
                    offers_total_count_element = next_element(code.parent)
                    supplier_hash[:offers_total_count] = offers_total_count_element.inner_text.strip.to_i

                  elsif code_text.match(/V\.*.*?[^\d]1[^\d]$/) && (header_text.match(/Počet uchádzačov/))
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

                  elsif (code_text.match(/V\.*.*?[^\d]3[^\d]$/) || code_text.match(/V\.*.*?[^\d]4[^\d]$/)) && (header_text.match(/Názov a adresa/) || header_text.match(/NÁZOV A ADRESA/) || header_text.match(/Meno(.*)adresa(.*)víťaza/))
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

                  elsif (code_text.match(/V\.*.*?[^\d]4[^\d]$/) || code_text.match(/V\.*.*?[^\d]5[^\d]$/)) && (header_text.match(/Informácie o hodnote/) || header_text.match(/INFORMÁCIE O HODNOTE/) || header_text.match(/HODNOTA/))
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


    end
  end
end
