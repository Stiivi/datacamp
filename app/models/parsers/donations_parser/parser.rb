# -*- encoding : utf-8 -*-
require 'csv'

module Parsers
  module DonationsParser
    class Parser
      ATTRIBUTES = [
                      :year,
                      :name,
                      :address,
                      :town,
                      :zip_code,
                      :district,
                      :region,
                      :in,
                      :number,
                      :contract_date,
                      :decision_date,
                      :project_name,
                      :program_number,
                      :requested,
                      :approved,
                      :currency
                    ]

      def self.parse_location(year)
        "registerkultury.gov.sk/proposals/#{year}.csv"
      end

      def self.parse(html, year)
        ::Parsers::Support.save(parse_location(year), 'csv', bucketize: false)
        CSV.open(::Parsers::Support.get_path(parse_location(year), bucketize: false), "wb", force_quotes: true) do |csv|
          csv << ATTRIBUTES

          doc = Nokogiri::HTML(html)
          doc.css('table table table table table tr, table.mensiepismo tr').each do |tr| # mensiepismo for 2007
            tds =  tr.css('td')
            if tds[0] and tds[0].text =~ /^\s*\d+/
              proposal = {}
              proposal[:year] = year

              if year < 2013
                proposal.merge! parse_recipient_2007_2012(tds[1])
              else
                proposal.merge! parse_recipient_2013(tds[1])
              end

              town, zip_code = parse_town_and_zip_code(proposal[:address])
              proposal[:town] = town
              proposal[:zip_code] = zip_code

              if proposal[:project_name].present? # different columns for 2007
                proposal[:program_number] = clean_string(tds[2].text)
                proposal[:requested], proposal[:requested_currency] = parse_donation(tds[3])
                proposal[:approved], proposal[:approved_currency] = parse_donation(tds[4])
              else
                proposal[:project_name] = clean_string(tds[2].text)
                proposal[:program_number] = clean_string(tds[3].text)
                proposal[:requested], proposal[:requested_currency] = parse_donation(tds[4])
                proposal[:approved], proposal[:approved_currency] = parse_donation(tds[5])
              end

              proposal[:currency] = proposal[:requested_currency] || proposal[:approved_currency]

              csv << ATTRIBUTES.map{ |a| proposal.fetch(a, nil) }
            end
          end
        end
      end

      private
        def self.parse_town_and_zip_code(address)
          town_and_zip_code = address.split(',').last
          zip_code = town_and_zip_code[0..5].gsub(' ','').strip
          town = town_and_zip_code[6..-1].strip
          return town, zip_code
        end

        def self.parse_recipient_2013(td)
          proposal = {}
          e = td.css('span.cervene').first
          return proposal unless e
          proposal[:name] = clean_string(e.text)
          e = td.children[3]
          proposal[:address] = clean_string(e.children[0].text, :remove_trailing_comma => true)
          it = 1
          while it < e.children.count
            case e.children[it].text.strip
              when 'okres:'
                proposal[:district] = clean_string(e.children[it+1].text)
                it+= 1
              when 'kraj:'
                proposal[:region] = clean_string(e.children[it+1].text)
                it+= 2
              when 'IČO:'
                proposal[:in] = clean_string(e.children[it+1].text, :remove_spaces => true)
                it+= 2
              when "evid. číslo žiadosti:"
                proposal[:number] = clean_string(e.children[it+1].text)
                it+= 2
              when "dátum rozhodnutia:"
                proposal[:decision_date] = clean_string(e.children[it+1].text)
                it+= 2
              when 'dátum uzatvorenia zmluvy:'
                proposal[:contract_date] = clean_string(e.children[it+1].text)
                it+= 2
            end
            it+= 1
          end
          proposal
        end

        def self.parse_recipient_2007_2012(td)
          proposal = {}
          e = td.css('span.cervene').first
          return proposal unless e
          proposal[:name] = clean_string(e.text)
          e = e.next.next
          proposal[:address] = clean_string(e.text, :remove_trailing_comma => false)
          if proposal[:address][-1] == ','
            e = e.next.next
            proposal[:address] << clean_string(e.text)
          end
          while e.next
            e = e.next
            case e.text.strip
              when 'okres:'
                proposal[:district] = clean_string(e.next.text)
              when 'kraj:'
                proposal[:region] = clean_string(e.next.text)
              when 'IČO:'
                proposal[:in] = clean_string(e.next.text, :remove_spaces => true)
              when "evidenčné číslo žiadosti:"
                proposal[:number] = clean_string(e.next.text)
              when 'dátum uzatvorenia zmluvy:'
                proposal[:contract_date] = clean_string(e.next.text)
              when /^Projekt: (.*)/ # Projekt: for 2007
                proposal[:project_name] = clean_string($1)
            end
          end
          proposal
        end

        def self.parse_donation(e)
          amount = e.children.first.text.gsub(/(\d)\D(\d)/, '\1\2').to_i
          currency = nil
          if amount > 0
            currency = e.children.first.text.gsub(/(\d{1,3}.)+(\w+)/, '\2').strip
            currency = (currency == 'Eur' ? 'EUR' : 'SKK')
          end
          [amount, currency]
        end

        def self.clean_string(str, options = {})
          options.reverse_merge!({
            :remove_trailing_comma => true,
            :remove_spaces => false
          })
          str = str.strip.squeeze(' ').tr("\n\t\r", '')
          str = str.sub(/,\Z/, '') if options[:remove_trailing_comma]
          str = str.tr(' ', '') if options[:remove_spaces]
          str
        end
    end
  end
end
