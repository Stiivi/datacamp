# -*- encoding : utf-8 -*-

module Etl
  class VvoChecker

    def self.check_all
      current_year = Date.today.year
      diff = 0
      last_year_missed = []
      (2009..current_year).each do |year|
        missed, in_addition, total_vvo, total_dataset  = check_for_year(year)
        puts "Year #{year}"
        puts "VVO: #{total_vvo} / Dataset: #{total_dataset}"
        puts "Missed (#{missed.count}): #{missed.inspect}"
        puts "In addition (#{in_addition.count}): #{in_addition.inspect}"
        puts "Missed from #{year-1} is in #{year}" if last_year_missed - in_addition == []
        year_diff = in_addition.count - missed.count
        diff += year_diff
        last_year_missed = missed
        puts "Summary in year / total: #{year_diff} / #{diff}"
        puts "-----"
      end
    end

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
      return missed, in_addition, document_ids.count, all_in_dataset.count
    end

  end
end
