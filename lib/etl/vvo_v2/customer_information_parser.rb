# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module CustomerInformationParser

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
                        activities << next_tr.inner_text.strip if next_tr.inner_text.strip.present?
                        next_tr = next_tr.next_sibling
                      end
                      content = activities.join(', ')
                    end
                    customer_information_hash[:customer_main_activity] = content if content.present? && customer_information_hash[:customer_main_activity].blank?
                  elsif header2.match(/Hlavný predmet alebo predmety činnosti/)
                    activities = [tr.xpath(".//td[2]//table[1]").inner_text.strip]
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

    end
  end
end
