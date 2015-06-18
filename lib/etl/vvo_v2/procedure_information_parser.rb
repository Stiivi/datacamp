# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module ProcedureInformationParser

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


    end
  end
end
