# -*- encoding : utf-8 -*-

module Etl
  class VvoChecker

    def self.check_for_year(year)
      f = File.open Rails.root.join('data', 'development', 'vvo', year.to_s + '.html')
      html = f.read
      f.close
      document = Nokogiri::HTML(html)
      css_links = document.css('#layout-column_column-2 .portlet-body .oznamenie .ozn1 a')
      document_ids = []
      css_links.each do |css_link|
        valid_link = css_link.inner_text.match(/(\d*)(\ )(\-)(\ )(...)/u)
        if valid_link && valid_link[5].start_with?('V')
          href = css_link.attributes['href'].text
          document_id = href.match(/(\D*)(\/)(\d*)(\D*)/u)[3].to_i
          document_ids << document_id
        end
      end

      exist_in_dataset = Staging::StaProcurement.select(:document_id).where(year: year, document_id: document_ids).map(&:document_id).uniq
      all_in_dataset = Staging::StaProcurement.select(:document_id).where(year: year).group(:document_id).count.keys
      missed = document_ids - exist_in_dataset
      in_addition = all_in_dataset - document_ids
      puts document_ids.inspect
      puts "Count: #{document_ids.uniq.count}"
      puts "Missed: #{missed.inspect}"
      puts "In addition: #{in_addition.inspect}"
    end

  end
end
