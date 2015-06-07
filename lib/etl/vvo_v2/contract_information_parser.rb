# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module ContractInformationParser

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
                      tr_subjects = tr.next_element
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

    end
  end
end
