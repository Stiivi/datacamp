# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module BasicInformationParser

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

    end
  end
end
