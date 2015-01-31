# -*- encoding : utf-8 -*-

module Etl
  module VvoV2
    module ParserIncludes

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
        if price_element.inner_text.match(/s DPH/)
          price_hash[:price_vat_included] = true
          vat_rate_element = next_element(price_element)
          if vat_rate_element && (vat_rate_element.inner_text.match(/Sadzba DPH/) && vat_rate_element.inner_text.size < 20)
            price_hash[:price_vat_rate] = parse_float(vat_rate_element.xpath(".//span").inner_text.strip)
          end
        elsif price_element.inner_text.match(/bez DPH/)
          price_hash[:price_vat_included] = false
        end
        vat_element = next_element(price_element)
        if vat_element && vat_element.inner_text.match(/Mena/)
          price_hash[:currency] = parse_currency(vat_element.xpath(".//span").inner_text.strip)
          vat_element = next_element(vat_element)
        end
        if vat_element && vat_element.inner_text.match(/Bez DPH/)
          price_hash[:price_vat_included] = false
        elsif vat_element && vat_element.inner_text.match(/Vrátane DPH/)
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
          price_hash[:currency] = parse_currency(price_elements[1].inner_text.strip)
          price_hash[:price_interval] = false
        elsif price_elements.size == 3
          price_hash[:price_range] = true
          price_hash[:price_min] = parse_float(price_elements[0].inner_text.strip)
          price_hash[:price_max] = parse_float(price_elements[1].inner_text.strip)
          price_hash[:currency] = parse_currency(price_elements[2].inner_text.strip)
        end
        if price_element.inner_text.match(/s DPH/)
          price_hash[:price_vat_included] = true
          vat_rate_element = next_element(price_element)
          if vat_rate_element.inner_text.match(/Sadzba DPH/)
            price_hash[:price_vat_rate] = parse_float(vat_rate_element.xpath(".//span").last.inner_text.strip)
          end
        elsif price_element.inner_text.match(/bez DPH/)
          price_hash[:price_vat_included] = false
        end
        vat_element = next_element(price_element)
        if vat_element && vat_element.inner_text.match(/Mena/)
          price_hash[:currency] = parse_currency(vat_element.xpath(".//span[@class='hodnota']").inner_text.strip)
          vat_element = next_element(vat_element)
        end
        if vat_element && vat_element.inner_text.match(/Bez DPH/)
          price_hash[:price_vat_included] = false
        elsif vat_element && vat_element.inner_text.match(/Vrátane DPH/)
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

      def normalize_notification_number(number)
        return nil unless number
        number.gsub!(" číslo", "")
        number.gsub!(": ", "") if number.start_with?(": ")
        return nil unless number.match(/\d/)
        number
      end

    end
  end
end
