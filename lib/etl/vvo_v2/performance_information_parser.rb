# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module PerformanceInformationParser

      # Performance information
      # Only for performace
      def performance_information
        performance_information_hash = {}

        case document_format
          when :format1
            document.xpath("//fieldset[@class='fieldset']/legend").each do |element|
              if element.inner_text.match(/ODDIEL\s+V\W/)
                performance_information_element = element.next_sibling.next_sibling
                performance_information_element.xpath(".//span[@class='code']").each do |code|
                  code_text = code.inner_text.strip
                  header_text = code.parent.xpath(".//span[@class='title']").inner_text

                  if code_text.match(/V\.*.*?[^\d]1.1[^\d]$/) && header_text.match(/Názov a označenie zmluvy/)
                    contract_name_element = next_element(code.parent)
                    performance_information_hash[:contract_name] = contract_name_element.inner_text.strip

                  elsif code_text.match(/V\.*.*?[^\d]1.2[^\d]$/) && header_text.match(/Dátum uzatvorenia zmluvy/)
                    subject_delivered_element = next_element(code.parent)
                    performance_information_hash[:contract_date] = parse_date(subject_delivered_element.inner_text)

                  elsif code_text.match(/V\.*.*?[^\d]2.1[^\d]$/) && header_text.match(/Názov a označenie dodatku k zmluve/)
                    subcontract_element = next_element(code.parent)
                    performance_information_hash[:subcontract_name] = subcontract_element.inner_text.strip

                  elsif code_text.match(/V\.*.*?[^\d]2.2[^\d]$/) && header_text.match(/Dátum uzatvorenia dodatku k zmluve/)
                    subcontract_element = next_element(code.parent)
                    performance_information_hash[:subcontract_date] = parse_date(subcontract_element.inner_text.strip)

                  elsif code_text.match(/V\.*.*?[^\d]2.3[^\d]$/) && header_text.match(/Dôvod uzatvorenia dodatku k zmluve/)
                    subcontract_element = next_element(code.parent)
                    performance_information_hash[:subcontract_reason] = subcontract_element.inner_text.strip

                  elsif code_text.match(/V\.*.*?[^\d]3.1[^\d]$/) && header_text.match(/ukončené dodaním predmetu zmluvy/)
                    subject_delivered_element = next_element(code.parent)
                    performance_information_hash[:subject_delivered] = !subject_delivered_element.inner_text.match(/Nie/)

                  elsif code_text.match(/V\.*.*?[^\d]3.2[^\d]$/) && header_text.match(/Pôvodná zmluvná cena/)
                    price_element = code.parent
                    begin
                      if price_element.inner_text.strip.match(/Pôvodná zmluvná cena/)
                        price_value_element = next_price_value_element(price_element)
                        if price_value_element
                          price_hash = parse_price1(price_value_element)
                          performance_information_hash[:procurement_currency] = price_hash[:currency]
                          performance_information_hash[:draft_price] = price_hash[:price]
                          performance_information_hash[:draft_price_vat_included] = price_hash[:price_vat_included]
                          performance_information_hash[:draft_price_vat_rate] = price_hash[:price_vat_rate]
                        end
                      elsif price_element.inner_text.strip.match(/Skutočne zaplatená cena/)
                        price_value_element = next_price_value_element(price_element)
                        if price_value_element
                          price_hash = parse_price1(price_value_element)
                          performance_information_hash[:procurement_currency] = price_hash[:currency]
                          performance_information_hash[:final_price] = price_hash[:price]
                          performance_information_hash[:final_price_vat_included] = price_hash[:price_vat_included]
                          performance_information_hash[:final_price_vat_rate] = price_hash[:price_vat_rate]
                        end
                      elsif price_element.inner_text.strip.match(/Odôvodnenie rozdielu/)
                        performance_information_hash[:price_difference_reason] = price_element.xpath(".//span[2]").inner_text
                      end

                      price_element = next_element(price_element)
                    end while price_element && price_element.xpath(".//span[@class='code']").inner_text.blank?

                  elsif code_text.match(/V\.*.*?[^\d]3.3[^\d]$/) && header_text.match(/Trvanie zmluvy/)
                    duration_element = next_element(code.parent)
                    while duration_element && duration_element.xpath(".//span[@class='code']").inner_text.blank?
                      if duration_element.inner_text.match(/Trvanie/)
                        performance_information_hash[:duration_unit] = duration_element.xpath(".//span[1]").inner_text.strip
                      elsif duration_element.inner_text.match(/Hodnota/)
                        performance_information_hash[:duration] = duration_element.xpath(".//span[1]").inner_text.to_i
                      elsif duration_element.inner_text.strip.match(/Odôvodnenie rozdielu/)
                        performance_information_hash[:duration_difference_reason] = duration_element.xpath(".//span[2]").inner_text.strip
                      elsif duration_element.inner_text.match(/Začiatok/)
                        performance_information_hash[:start_on] = parse_date(duration_element.xpath(".//span[1]").inner_text.strip)
                      elsif duration_element.inner_text.match(/Ukončenie/)
                        performance_information_hash[:end_on] = parse_date(duration_element.xpath(".//span[1]").inner_text.strip)
                      end
                      duration_element = next_element(duration_element)
                    end

                  end
                end
              end
            end
          when :format2
            document.xpath("//table[@class='mainTable']//td[@class='cast']").each do |element|
              if element.inner_text.match(/ODDIEL\s+V\W/)
                element.xpath(".//table")[0].xpath(".//tr").each do |tr|
                  code_text = tr.xpath(".//td[@class='kod']").inner_text.strip
                  header_text = tr.xpath(".//td[2]//span[@class='nazov']").inner_text.strip

                  if code_text.match(/V\.*.*?[^\d]1.1[^\d]$/) && header_text.match(/Názov a označenie zmluvy/)
                    performance_information_hash[:contract_name] = strip_last_point(tr.xpath(".//span[@class='hodnota']").inner_text.strip)

                  elsif code_text.match(/V\.*.*?[^\d]1.2[^\d]$/) && header_text.match(/Dátum uzatvorenia zmluvy/)
                    performance_information_hash[:contract_date] = parse_date(tr.xpath(".//span[@class='hodnota']").inner_text.strip)

                  elsif code_text.match(/V\.*.*?[^\d]2.1[^\d]$/) && header_text.match(/Názov a označenie dodatku k zmluve/)
                    performance_information_hash[:subcontract_name] = strip_last_point(tr.xpath(".//span[@class='hodnota']").inner_text)

                  elsif code_text.match(/V\.*.*?[^\d]2.2[^\d]$/) && header_text.match(/Dátum uzatvorenia dodatku k zmluve/)
                    performance_information_hash[:subcontract_date] = parse_date(tr.xpath(".//span[@class='hodnota']").inner_text.strip)

                  elsif code_text.match(/V\.*.*?[^\d]2.3[^\d]$/) && header_text.match(/Dôvod uzatvorenia dodatku k zmluve/)
                    performance_information_hash[:subcontract_reason] = strip_last_point(tr.xpath(".//span[@class='hodnota']").inner_text.strip)

                  elsif code_text.match(/V\.*.*?[^\d]3.1[^\d]$/) && header_text.match(/ukončené dodaním predmetu zmluvy/)
                    performance_information_hash[:subject_delivered] = !tr.xpath(".//span[@class='hodnota']").inner_text.match(/Nie/)

                  elsif code_text.match(/V\.*.*?[^\d]3.2[^\d]$/) && header_text.match(/Pôvodná zmluvná cena/)
                    price_element = tr
                    begin
                      if price_element.inner_text.strip.match(/Pôvodná zmluvná cena/)
                        price_value_element = next_price_value_element(price_element)
                        if price_value_element
                          price_hash = parse_price2(price_value_element)
                          performance_information_hash[:procurement_currency] = price_hash[:currency]
                          performance_information_hash[:draft_price] = price_hash[:price]
                          performance_information_hash[:draft_price_vat_included] = price_hash[:price_vat_included]
                          performance_information_hash[:draft_price_vat_rate] = price_hash[:price_vat_rate]
                        end
                      elsif price_element.inner_text.strip.match(/Skutočne zaplatená cena/)
                        price_value_element = next_price_value_element(price_element)
                        if price_value_element
                          price_hash = parse_price2(price_value_element)
                          performance_information_hash[:procurement_currency] = price_hash[:currency]
                          performance_information_hash[:final_price] = price_hash[:price]
                          performance_information_hash[:final_price_vat_included] = price_hash[:price_vat_included]
                          performance_information_hash[:final_price_vat_rate] = price_hash[:price_vat_rate]
                        end
                      elsif price_element.inner_text.strip.match(/Odôvodnenie rozdielu/)
                        performance_information_hash[:price_difference_reason] = strip_last_point(price_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                      end

                      price_element = next_element(price_element)
                    end while price_element && price_element.xpath(".//td[@class='kod']").inner_text.blank?

                  elsif code_text.match(/V\.*.*?[^\d]3.3[^\d]$/) && header_text.match(/Trvanie zmluvy/)
                    duration_element = next_element(tr)
                    while duration_element && duration_element.xpath(".//td[@class='kod']").inner_text.blank?
                      if duration_element.xpath(".//span[@class='podnazov']").inner_text.match(/Trvanie/)
                        duration_unit = strip_last_point(duration_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                        performance_information_hash[:duration_unit] = duration_unit if duration_unit != "v intervale"
                      elsif duration_element.xpath(".//span[@class='podnazov']").inner_text.match(/Hodnota/)
                        performance_information_hash[:duration] = duration_element.xpath(".//span[@class='hodnota']").inner_text.to_i
                      elsif duration_element.xpath(".//span[@class='podnazov']").inner_text.strip.match(/Odôvodnenie rozdielu/)
                        performance_information_hash[:duration_difference_reason] = strip_last_point(duration_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                      elsif duration_element.xpath(".//span[@class='podnazov']").inner_text.match(/Začiatok/)
                        performance_information_hash[:start_on] = parse_date(duration_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                      elsif duration_element.xpath(".//span[@class='podnazov']").inner_text.match(/Ukončenie/)
                        performance_information_hash[:end_on] = parse_date(duration_element.xpath(".//span[@class='hodnota']").inner_text.strip)
                      end
                      duration_element = next_element(duration_element)
                    end
                  end

                end
              end
            end

          else

        end
        performance_information_hash
      end

    end
  end
end
