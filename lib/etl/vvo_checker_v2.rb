# -*- encoding : utf-8 -*-
require 'mechanize'

module Etl
  class VvoCheckerV2

    START_YEAR = 2009

    def self.check_all
      diffs_by_year = {
          notice: procurements_diffs(:notice),
          performance: procurements_diffs(:performance),
      }
      diffs = {}
      [:notice, :performance].each do |dataset_type|
        diffs[dataset_type] = {}
        [:real, :filter].each do |type|
          diffs[dataset_type][type] = {
              diffs_by_year: diffs_by_year[dataset_type][type],
              summary_diff: summary_diff(diffs_by_year[dataset_type][type]),
          }
        end
      end
      EtlMailer.vvo_v2_checker_report(diffs).deliver
    end

    def self.summary_diff(diffs_by_year)
      summary_diff = {existing_count: 0,
                      total_count: 0,
                      diff: 0}
      diffs_by_year.each_pair do |_, diff|
        summary_diff[:existing_count] += diff[:existing_count]
        summary_diff[:total_count] += diff[:total_count]
        summary_diff[:diff] += diff[:diff]
      end
      summary_diff
    end

    def self.procurements_diffs(dataset_type)
      diffs = {filter: {}, real: {}}
      dataset = Etl::VvoExtractionV2.dataset_table(dataset_type)
      last_year = Date.today.year

      all_procurements_by_year = {}
      (START_YEAR..last_year).each { |year| all_procurements_by_year[year] = [] }

      (START_YEAR..last_year).each do |year|
        procurements_in_year_by_filter = extract_procurements(dataset_type, year)
        diffs[:filter][year] = procurements_diff_by_year(dataset, year, procurements_in_year_by_filter)
      end

      # all procurements
      all_procurements = extract_procurements(dataset_type, nil)
      all_procurements.each do |procurement|
        all_procurements_by_year[procurement[:date].year] << procurement
      end

      (START_YEAR..last_year).each do |year|
        diffs[:real][year] = procurements_diff_by_year(dataset, year, all_procurements_by_year[year])
      end

      diffs
    end

    def self.procurements_diff_by_year(dataset, year, procurements_in_year)
      document_ids = procurements_in_year.map { |p| p[:document_id] }
      exist_in_dataset = dataset.select(:document_id).where(year: year, document_id: document_ids).map(&:document_id).uniq
      all_in_dataset = dataset.select(:document_id).where(year: year).group(:document_id).count.keys
      missed = document_ids - exist_in_dataset
      in_addition = all_in_dataset - document_ids
      diff = in_addition.count - missed.count

      {existing_count: all_in_dataset.count,
       total_count: procurements_in_year.count,
       missed: missed,
       in_addition: in_addition,
       diff: diff}
    end

    # ----------------

    # V.. - Oznámenia o výsledku verejného obstarávania
    # IP. - Informácie o uzavretí zmluvy

    # IZ., ID. - Informácia o plnení zmluvy

    LINKS = {
        notice: ["Oznámenia o výsledku verejného obstarávania", "Informácie o uzavretí zmluvy"],
        performance: ["Informácia o plnení zmluvy"]
    }
    SEARCH_URL = "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/searchResult"

    def self.extract_procurements(type, year)
      procurements = []
      LINKS[type].each do |link|
        link_match = %r{#{"#{link} (.*)"}}
        year_match = year ? %r{#{"#{year} (.*)"}} : nil
        # html
        puts "Stahujem: #{year} - #{link}"
        html = download_procurements(link_match, year_match)
        puts "Spracovavam: #{year} - #{link}"
        if html
          current_procurements = parse_procurements(html)
          procurements += current_procurements
          puts "Spracoval som: #{current_procurements.size} procurements"
        else
          puts "Nenasiel som ziadne procurements"
        end
      end
      procurements
    end

    def self.download_procurements(link_match, year_match)
      agent = Mechanize.new
      agent.get(SEARCH_URL)
      if year_match
        link_element = agent.page.link_with(text: year_match)
        return nil unless link_element
        link_element.click
      end
      link_element = agent.page.link_with(text: link_match)
      return nil unless link_element
      link_element.click
      agent.page.link_with(text: /Ďalšia/).click
      uri = agent.page.uri.to_s.gsub("_perPage=30", "_perPage=100000").gsub("&cur=2", "&cur=1")
      agent.get(uri)
      agent.page.body
    end

    def self.parse_procurements(html)
      procurements = []
      document = Nokogiri::HTML(html)
      document.css('#layout-column_column-2 .ozn1').each do |header|
        css_link = header.css("a").first
        href = css_link.attributes['href'].text
        document_id = href.match(/(\D*)(\/)(\d*)(\D*)/u)[3].to_i
        title = css_link.inner_text.match(/(\d*)(\ )(\-)(\ )(...)/u)
        bulletin_and_date = header.css(".datum").inner_text.match(/Zverejnené: (.*) vo VVO (.*)/u)
        date = Date.parse(bulletin_and_date[1]) rescue nil
        bulletin_code = bulletin_and_date[2]
        procurements << {document_id: document_id, document_type: title[5], date: date, bulletin_code: bulletin_code}
      end
      procurements
    end

  end
end
