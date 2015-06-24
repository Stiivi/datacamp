# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module AdditionalInformationParser

      # Additional information

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

                  elsif code_text.match(/VI\.*.*?[^\d]1.2[^\d]$/) && header_text.match(/Zverejnené oznámenie/)
                    notification_element = next_element(code.parent)
                    eu_number = eu_published_on = vvo_number = vvo_published_on = nil
                    while notification_element && notification_element.xpath(".//span[@class='code']").inner_text.blank?
                      if notification_element.inner_text.match(/Číslo oznámenia v(.*)EÚ/)
                        if notification_element.xpath(".//span")
                          eu_number = notification_element.xpath(".//span").inner_text.strip
                          date_element = notification_element.xpath(".//span").first.next_sibling
                          if date_element
                            eu_published_on = parse_date(date_element.inner_text.strip.gsub("z: ", ""))
                          end
                        end
                      elsif notification_element.inner_text.match(/Číslo oznámenia vo VVO/)
                        matches = notification_element.inner_text.match(/(.*)VVO:(.*) z (.*)/)
                        if matches && matches.size == 4
                          vvo_number = matches[2].strip
                          vvo_published_on = parse_date(matches[3].strip)
                        end
                      end
                      notification_element = next_element(notification_element)
                    end
                    vvo_number = normalize_notification_number(vvo_number)
                    eu_number = normalize_notification_number(eu_number)
                    additional_information_hash[:eu_notification_number] = eu_number
                    additional_information_hash[:eu_notification_published_on] = eu_published_on
                    additional_information_hash[:vvo_notification_number] = vvo_number
                    additional_information_hash[:vvo_notification_published_on] = vvo_published_on
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

                  elsif code_text.match(/VI\.*.*?[^\d]1.2[^\d]$/) && header_text.match(/Zverejnené oznámenie o výsledku verejného obstarávania/)
                    notification_element = next_element(tr)
                    eu_number = eu_published_on = vvo_number = vvo_published_on = nil
                    while notification_element && notification_element.xpath(".//td[@class='kod']").inner_text.blank?
                      if notification_element.inner_text.match(/Číslo oznámenia v(.*)EÚ/)
                        matches = notification_element.xpath(".//span[@class='hodnota']").inner_text.match(/(.*) z (.*)/)
                        if matches && matches.size == 3
                          eu_number = matches[1].strip
                          eu_published_on = parse_date(matches[2].strip)
                        end
                      elsif notification_element.inner_text.match(/Číslo oznámenia vo VVO/)
                        matches = notification_element.xpath(".//span[@class='hodnota']").inner_text.match(/(.*) z (.*)/)
                        if matches && matches.size == 3
                          vvo_number = matches[1].strip
                          vvo_published_on = parse_date(matches[2].strip)
                        end
                      end
                      notification_element = next_element(notification_element)
                    end
                    vvo_number = normalize_notification_number(vvo_number)
                    eu_number = normalize_notification_number(eu_number)
                    additional_information_hash[:eu_notification_number] = eu_number
                    additional_information_hash[:eu_notification_published_on] = eu_published_on
                    additional_information_hash[:vvo_notification_number] = vvo_number
                    additional_information_hash[:vvo_notification_published_on] = vvo_published_on
                  end

                end
              end
            end

          else

        end
        additional_information_hash
      end

    end
  end
end
