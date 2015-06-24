# -*- encoding : utf-8 -*-

module Etl
  module Shared
    module VvoIncludes

      # private

      def update_report_object(type, key, value)
        data = config.reload.last_run_report[type]
        data[key] = value
        config.update_report!(type, data)
      end

      def update_report_object_depth_2(type1, type2, key, value)
        data = config.reload.last_run_report[type1][type2]
        data[key] = value
        res = config.last_run_report[type1]
        res[type2.to_sym] = data
        config.update_report!(type1, res)
      end

      def get_path(path, options = {})
        defaults = {
            :bucketize => true
        }
        options = defaults.merge(options)

        if options[:bucketize]
          path_chunks = path.split('/')
          output = []
          path_chunks.each do |chunk|
            numbers = chunk.scan(/[0-9]{3,}/).collect do |part|
              part.to_i / 1000 * 1000
            end
            output += numbers if numbers.any?
            output << chunk
          end
          "#{Rails.root}/data/#{Rails.env}/#{output.join('/')}"
        else
          "#{Rails.root}/data/#{Rails.env}/#{path}"
        end
      end

      # parsing

      def next_element(element)
        element = element.next_sibling
        while element && element.inner_text.strip.blank?
          element = element.next_sibling
        end
        element
      end

      def strip_last_point(str)
        return unless str
        str.gsub(/\.$/, "")
      end

      def parse_date(str)
        return nil unless str
        Date.parse(str) rescue nil
      end

      def parse_float(str)
        return 0 unless str
        str.gsub(' ', '').gsub(',', '.').to_f
      end

      def parse_currency(str)
        return nil unless str
        str.downcase.match(/sk|skk/) ? "SKK" : "EUR"
      end

      def parse_organisation_code(str)
        str.gsub(" ", "")
      end

      def parse_address(full_address)
        zip = place = ''
        items = full_address.split(',')
        if items.size < 3
          address = items[0]
          zip_and_place = items[1]
        else
          address = items[0..-2].join(',')
          zip_and_place = items[-1]
        end
        if zip_and_place
          zip_and_place.strip!
          matches = zip_and_place.match(/(\d{5})\ (.*)/) || zip_and_place.match(/(\d{3})\ (\d{2})\ (.*)/)
          if matches
            place = matches[-1]
            if matches.size == 3
              zip = matches[1]
            elsif matches.size == 4
              zip = matches[1] + matches[2]
            end
          else
            place = zip_and_place
          end
        end
        address.strip! if address
        zip.strip! if zip
        place.strip! if place
        return address, zip, place
      end

      def parse_zip(str)
        str.gsub(" ", "").strip
      end

      def mostly_numbers?(str)
        str.chars.select { |ch| ch.match(/\d/) }.count > (str.size / 2)
      end

    end
  end
end
