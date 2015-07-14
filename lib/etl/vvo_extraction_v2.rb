# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class VvoExtractionV2
    include Etl::Shared::VvoIncludes
    include Etl::VvoV2::BasicInformationParser
    include Etl::VvoV2::ParserIncludes
    include Etl::VvoV2::CustomerInformationParser
    include Etl::VvoV2::AdditionalInformationParser
    include Etl::VvoV2::ProcedureInformationParser
    include Etl::VvoV2::SuppliersInformationParser
    include Etl::VvoV2::ContractInformationParser
    include Etl::VvoV2::PerformanceInformationParser

    # -- helper for parsing --

    # notice_result
    # contract_info
    def self.parse_all_downloaded_documents_for_type(dataset_type)
      ids = Dir.glob("data/#{Rails.env}/vvo/procurements/*/*.html").map { |n| File.basename(n, ".html").to_i }
      ids.each_with_index do |document_id, index|
        ext = Etl::VvoExtractionV2.new(document_id)
        if ext.dataset_type == dataset_type
          begin
            ext.digest
          rescue
            puts document_id # exceptions, errors
          end
        end
        if index % 1000 == 0
          puts "#{index} / #{ids.size}"
        end
      end
      nil
    end

    def self.save_all_downloaded_documents_for_type(dataset_type)
      ids = Dir.glob("data/#{Rails.env}/vvo/procurements/*/*.html").map { |n| File.basename(n, ".html").to_i }
      puts "Downloaded documents: #{ids.count}"
      ids.each do |document_id|
        ext_temp = Etl::VvoExtractionV2.new(document_id)
        if ext_temp.dataset_type == dataset_type
          Delayed::Job.enqueue Etl::VvoExtractionV2.new(document_id)
        end
      end
      nil
    end

    # Dataset type

    # V.., IP.,
    # IZ., ID.

    def self.dataset_type(document_type)
      return nil unless document_type
      if document_type.start_with?('V') || document_type.start_with?('IP')
        :notice
      elsif document_type.start_with?('IZ') || document_type.start_with?('ID')
        :performance
      else
        nil
      end
    end

    def self.dataset_table(dataset_type)
      case dataset_type
        when :notice
          Kernel::DsProcurementV2Notice
        when :performance
          Kernel::DsProcurementV2Performance
        else
      end
    end

    # -- base --

    attr_reader :document_id, :report_extraction

    def initialize(document_id, report_extraction = false)
      @document_id = document_id
      @report_extraction = report_extraction
    end

    def document_url
      "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/#{document_id}"
    end

    def document
      return @document if @document
      html = download
      html.gsub!("&nbsp;", " ")
      @document = Nokogiri::HTML(html).xpath("//div[@class='oznamenie']")
    end

    def download
      filename = get_path("vvo/procurements/#{document_id}.html")
      if File.exist?(filename)
        f = File.open(filename)
        html = f.read
        f.close
        html
      else
        Typhoeus::Request.get(document_url).body
      end
    end


    def document_format
      @document_format ||= if document.xpath("./div[@class='MainHeader'][1]").any?
                             :format1
                           elsif document.xpath("./h2[@class='document_number_and_code'][1]").any?
                             :format2
                           elsif document.any?
                             :other
                           else
                             nil
                           end
    end

    def document_type
      @document_type ||= case document_format
                           when :format1
                             document.xpath("./div[@class='MainHeader'][1]").inner_text.match(/\w+$/)[0]
                           when :format2
                             document.xpath("./h2[@class='document_number_and_code'][1]").inner_text.match(/\w+$/)[0]
                           else
                             nil
                         end
    end

    def dataset_type
      Etl::VvoExtractionV2.dataset_type(document_type)
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('vvo_extraction_v2')
    end

    def is_acceptable?
      dataset_type.present?
    end

    def perform
      if is_acceptable?
        save
        # Update report after save
        update_report_after_save if report_extraction
      else
        # Missed extraction update not acceptable
        update_document_report(:not_acceptable) if report_extraction
      end
    end

    # Digest - for each dataset_type other

    def digest
      # common
      hashes = [basic_information, header_procedure_and_project_information, customer_information, contract_information]
      case dataset_type
        when :notice
          hashes += [procedure_information, suppliers_information, additional_information]
        when :performance
          hashes += [performance_information, additional_information]
        else
          hashes = []
      end
      digest_hash = hashes.first
      hashes[1..-1].each do |merge_hash|
        digest_hash.merge!(merge_hash)
      end
      digest_hash
    end


    def digest_attributes
      case dataset_type
        when :notice
          [
              # Basic information
              :procurement_code, :bulletin_code, :year, :procurement_type, :published_on,
              # Customer information
              :customer_name, :customer_organisation_code, :customer_address, :customer_place, :customer_zip, :customer_country,
              :customer_contact_persons, :customer_phone, :customer_mobile, :customer_email, :customer_fax,
              :customer_type, :customer_purchase_for_others, :customer_main_activity,
              # Contract information
              :project_name, :project_type, :project_category, :place_of_performance, :nuts_code, :project_description,
              :general_contract, :dictionary_main_subjects, :dictionary_additional_subjects, :gpa_agreement,
              # Procedure information
              :procedure_type, :procedure_offers_criteria, :procedure_use_auction, :previous_notification1_number, :previous_notification2_number, :previous_notification3_number, :previous_notification1_published_on, :previous_notification2_published_on, :previous_notification3_published_on,
              # Supplier information
              :contract_name, :contract_date, :offers_total_count, :offers_online_count, :offers_excluded_count,
              :supplier_name, :supplier_organisation_code, :supplier_address, :supplier_place, :supplier_zip, :supplier_country,
              :supplier_phone, :supplier_mobile, :supplier_email, :supplier_fax,
              :procurement_currency, :final_price, :final_price_range, :final_price_min, :final_price_max, :final_price_vat_included, :final_price_vat_rate,
              :draft_price, :draft_price_vat_included, :draft_price_vat_rate, :procurement_subcontracted,
              # Additional information
              :procurement_euro_found, :evaluation_committee
          ]
        when :performance
          [
              # Basic information
              :procurement_code, :bulletin_code, :year, :procurement_type, :published_on, :project_type,
              # Customer information
              :customer_name, :customer_organisation_code, :customer_address, :customer_place, :customer_zip, :customer_country,
              :customer_contact_persons, :customer_phone, :customer_mobile, :customer_email, :customer_fax,
              # Performance information
              :contract_name, :contract_date, :subject_delivered,
              :subcontract_name, :subcontract_date, :subcontract_reason,
              :procurement_currency, :final_price, :final_price_vat_included, :final_price_vat_rate, :price_difference_reason,
              :draft_price, :draft_price_vat_included, :draft_price_vat_rate,
              :start_on, :end_on, :duration, :duration_unit, :duration_difference_reason,
              # Additional information
              :eu_notification_number, :eu_notification_published_on, :vvo_notification_number, :vvo_notification_published_on,
          ]
        else
          []
      end
    end

    def save
      procurement_digest = digest

      # TODO refactor
      case dataset_type
        when :notice
          shorten_attributes = [:supplier_name, :customer_name]
          procurement_digest[:suppliers].each_with_index do |supplier_hash, supplier_index|
            procurement_hash = procurement_digest.dup
            procurement_hash.delete(:suppliers)
            procurement_hash.merge!(supplier_hash)

            # Initialize object
            procurement_object = Kernel::DsProcurementV2Notice.find_or_initialize_by_document_id_and_supplier_index(document_id, supplier_index)

            digest_attributes.each do |attribute|
              attribute_value = procurement_hash[attribute]
              # shorten attribute before save
              attribute_value = attribute_value.first(255) if attribute_value && shorten_attributes.include?(attribute)
              procurement_object[attribute] = attribute_value
            end
            procurement_object.document_url = document_url

            # Map customer to regis
            customer_regis_organisation = find_regis_organisation(procurement_hash[:customer_organisation_code])
            if customer_regis_organisation
              procurement_object.customer_organisation_id = customer_regis_organisation.id
              procurement_object.customer_regis_name = customer_regis_organisation.name
            end

            # Map supplier to regis
            supplier_regis_organisation = find_regis_organisation(procurement_hash[:supplier_organisation_code])
            if supplier_regis_organisation
              procurement_object.supplier_organisation_id = supplier_regis_organisation.id
              procurement_object.supplier_regis_name = supplier_regis_organisation.name
            end

            procurement_object.record_status = Dataset::RecordStatus.find(:published)
            procurement_object.save
          end

        when :performance
          shorten_attributes = [:customer_name]
          procurement_hash = procurement_digest

          # Initialize object
          procurement_object = Kernel::DsProcurementV2Performance.find_or_initialize_by_document_id(document_id)

          digest_attributes.each do |attribute|
            attribute_value = procurement_hash[attribute]
            # shorten attribute before save
            attribute_value = attribute_value.first(255) if attribute_value && shorten_attributes.include?(attribute)
            procurement_object[attribute] = attribute_value
          end
          procurement_object.document_url = document_url

          # Map customer to regis
          customer_regis_organisation = find_regis_organisation(procurement_hash[:customer_organisation_code])
          if customer_regis_organisation
            procurement_object.customer_organisation_id = customer_regis_organisation.id
            procurement_object.customer_regis_name = customer_regis_organisation.name
          end

          procurement_object.record_status = Dataset::RecordStatus.find(:published)
          procurement_object.save

        else
      end

    end

    def update_report_after_save
      case dataset_type
        when :notice
          if digest[:suppliers].size == 0
            update_document_report(:empty_suppliers)
          else
            update_document_report(:processed)
          end
        when :performance
          update_document_report(:processed)
        else
      end
    end

    private

    def find_regis_organisation(organisation_code)
      Kernel::DsOrganisation.find_by_ico(organisation_code.to_i)
    end

    def update_document_report(type)
      update_report_object_depth_2(EtlConfiguration::VVO_V2_KEYS_BY_TYPES[dataset_type], type, document_id, document_url)
    end

  end
end
