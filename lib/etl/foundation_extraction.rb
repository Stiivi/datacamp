# -*- encoding : utf-8 -*-
require 'etl/page_loader'

module Etl
  class FoundationExtraction
    # static
    def self.update_last_run_time
      EtlConfiguration.find_by_name('foundation_extraction').update_attribute(:last_run_time, Time.now)
      DatasetDescription.where(identifier: %w{foundations foundation_founders foundation_trustees foundation_liquidators}).update_all(data_updated_at: Time.zone.now)
    end

    attr_reader :doc_id, :document_url, :page_loader

    def initialize(doc_id, params = {})
      @doc_id = doc_id
      @page_loader = params.fetch(:page_loader) { Etl::PageLoader }
      @document_url = params.fetch(:document_url) { "http://www.ives.sk/registre/detailrnd.do?action=uplny&formular=&id=#{doc_id}&locale=sk" }
    end

    def perform
      save(page.foundation.merge(record_status: 'published'))
    end

    def page
      @page ||= page_loader.load_by_get(document_url, Etl::FoundationExtraction::FoundationPage, document_url: document_url, doc_id: doc_id)
    end

    def save(foundation_hash)
      return unless foundation_hash.present?
      current_foundation = Dataset::DsFoundation.find_or_initialize_by_ives_id(foundation_hash[:ives_id])

      unless current_foundation.new_record?
        foundation_hash[:ds_foundation_founders] = create_resources(:founder, current_foundation.ds_foundation_founders, foundation_hash.delete(:ds_foundation_founders_attributes))
        foundation_hash[:ds_foundation_trustees] = create_resources(:trustee, current_foundation.ds_foundation_trustees, foundation_hash.delete(:ds_foundation_trustees_attributes))
        foundation_hash[:ds_foundation_liquidators] = create_resources(:liquidator, current_foundation.ds_foundation_liquidators, foundation_hash.delete(:ds_foundation_liquidators_attributes))
      end

      current_foundation.update_attributes(foundation_hash)
    end

    def create_resources(resource_type, resources, attributes)
      all_ids = resources.map(&:_record_id)
      active_objects = []
      attributes.each do |obj_hash|
        case resource_type
          when :founder
            obj = resources.find_or_initialize_by_name_and_address_and_identification_number_and_contribution_value_and_contribution_currency_and_contribution_subject(obj_hash[:name], obj_hash[:address], obj_hash[:identification_number], obj_hash[:contribution_value], obj_hash[:contribution_currency], obj_hash[:contribution_subject])
          when :trustee
            obj = resources.find_or_initialize_by_name_and_address_and_trustee_from_and_trustee_to(obj_hash[:name], obj_hash[:address], obj_hash[:trustee_from], obj_hash[:trustee_to])
          when :liquidator
            obj = resources.find_or_initialize_by_name_and_address_and_liquidator_from_and_liquidator_to(obj_hash[:name], obj_hash[:address], obj_hash[:liquidator_from], obj_hash[:liquidator_to])
        end
        # publish resource
        obj.update_attributes(obj_hash.merge(record_status: 'published'))
        active_objects << obj
      end
      # deleted ids
      active_ids = active_objects.map(&:_record_id)
      old_ids = all_ids - active_ids
      resource_class = case resource_type
                         when :founder
                           Dataset::DsFoundationFounder
                         when :trustee
                           Dataset::DsFoundationTrustee
                         when :liquidator
                           Dataset::DsFoundationLiquidator
                       end
      # Suspend which deleted resources
      resource_class.where(_record_id: old_ids).update_all(record_status: 'suspended')
      active_objects
    end

    class FoundationPage
      attr_accessor :document_url, :doc_id

      attr_reader :document

      def initialize(document, params = {})
        @document = document
        @params = params
        @document_url = params.fetch(:document_url)
        @doc_id = params.fetch(:doc_id)
      end

      def foundation
        registration_number = identification_number = name = address = objective = ''
        date_start = date_end = date_liquidation = date_registration = ''
        assets_value = assets_currency = nil

        founders = []
        trustees = []
        liquidators = []

        document.xpath("//div[@class='divForm']//table//tr").each do |row|
          if row.xpath(".//td[1]").inner_text.match(/Registra(č|c)n(e|é) (c|č)(í|i)slo/i)
            registration_number = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/N(á|a)zov nad(á|a)cie/i)
            name = row.xpath(".//td[2]").inner_text.gsub('"','')
          elsif row.xpath(".//td[1]").inner_text.match(/S(í|i)dlo/i)
            address = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/^I(Č|C)O$/i)
            identification_number = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/D(á|a)tum vzniku/i)
            date_start = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/D(á|a)tum z(á|a)pisu/i)
            date_registration = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/D(á|a)tum z(á|a)niku/i)
            date_end = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/D(á|a)tum vstupu do likvid(á|a)cie/i)
            date_liquidation = row.xpath(".//td[2]").inner_text
          elsif row.xpath(".//td[1]").inner_text.match(/(Ú|U)(č|c)el nad(á|a)cie/i)
            objective = row.xpath(".//td[2]").inner_text.strip
          elsif row.xpath(".//td[1]").inner_text.match(/Aktu(á|a)lna hodnota nada(č|c)n(é|e)ho imania/i)
            assets = row.xpath(".//td[2]").inner_text[1..-2].strip.split(' ')
            if assets.size > 0
              assets_value = assets.first.to_f
              assets_currency = assets.last
            else
              assets_value = assets_currency = nil
            end
          elsif row.xpath(".//td[1]").inner_text.match(/Zakladatelia/i)
            founders = digest_founders row.xpath(".//td[2]//table")
          elsif row.xpath(".//td[1]").inner_text.match(/(Š|S)tatut(á|a)rny organ:(.)Spr(á|a)vca/i)
            trustees = digest_trustees_or_liquidators row.xpath(".//td[2]//table"), :trustee_from, :trustee_to
          elsif row.xpath(".//td[1]").inner_text.match(/Likvid(á|a)tori/i)
            liquidators = digest_trustees_or_liquidators row.xpath(".//td[2]//table"), :liquidator_from, :liquidator_to
          end
        end

        # Date parsers
        date_start = Date.parse(date_start) rescue nil
        date_registration = Date.parse(date_registration) rescue nil
        date_liquidation = Date.parse(date_liquidation) rescue nil
        date_end = Date.parse(date_end) rescue nil

        url = document_url.to_s

        { ives_id: doc_id,
          name: name,
          identification_number: identification_number,
          registration_number: registration_number,
          address: address,
          date_start: date_start,
          date_end: date_end,
          date_liquidation: date_liquidation,
          date_registration: date_registration,
          objective: objective,
          assets_currency: assets_currency,
          assets_value: assets_value,
          url: url,
          ds_foundation_founders_attributes: founders,
          ds_foundation_trustees_attributes: trustees,
          ds_foundation_liquidators_attributes: liquidators
        }
      end

      def digest_founders(table)
        founders = []
        table.xpath(".//tr").each do |founder_row|
          founder_identification = founder_row.xpath(".//td[1]").inner_text.strip.split("\n")
          founder_contribution = founder_row.xpath(".//td[3]").inner_text[1..-2].strip.split(' ')

          founder_name, founder_address = founder_identification[0].strip, founder_identification[1].strip
          if founder_identification.size > 2
            founder_identification_number = founder_identification[2].scan(/I(Č|C)O:(.)(.*)/).first.last
          else
            founder_identification_number = ''
          end

          if founder_contribution.size > 0
            founder_contribution_value = founder_contribution.first.to_f
            founder_contribution_currency = founder_contribution.last
          else
            founder_contribution_value = founder_contribution_currency = nil
          end
          founder_contribution_subject = founder_row.xpath(".//td[2]").inner_text.split("\n").last.strip.scan(/Predmet:(.)(.*)/).first.last

          founders << {
              name: founder_name,
              address: founder_address,
              identification_number: founder_identification_number,
              contribution_value: founder_contribution_value,
              contribution_currency: founder_contribution_currency,
              contribution_subject: founder_contribution_subject
          }
        end
        founders
      end

      def digest_trustees_or_liquidators(table, name_from, name_to)
        trustees_or_liquidators = []
        table.xpath(".//tr").each do |row|
          identification = row.xpath(".//td[1]").inner_text.strip.split("\n")
          name = identification[0].strip
          address = identification[1].strip
          date_from = row.xpath(".//td[3]").inner_text
          date_to = row.xpath(".//td[5]").inner_text

          date_from = Date.parse(date_from) rescue nil
          date_to = Date.parse(date_to) rescue nil

          trustees_or_liquidator = {
              name: name,
              address: address
          }
          trustees_or_liquidator[name_from] = date_from
          trustees_or_liquidator[name_to] = date_to
          trustees_or_liquidators << trustees_or_liquidator
        end
        trustees_or_liquidators
      end
    end
  end
end
