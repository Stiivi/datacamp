# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class NotarExtraction < Etl::Extraction
    def document_url(id)
      URI.encode "http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady/Notárskeúradydetail.aspx?id=#{id}"
    end

    def self.list_url
      URI.encode "http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady.aspx"
    end

    def self.update_last_run_time
      EtlConfiguration.find_by_name('notary_extraction').update_attribute(:last_run_time, Time.now)
      DatasetDescription.find_by_identifier('notaries').update_attribute(:data_updated_at, Time.zone.now)
      DatasetDescription.find_by_identifier('notary_employees').update_attribute(:data_updated_at, Time.zone.now)
    end

    def download(id)
      Nokogiri::HTML(Typhoeus::Request.get(document_url(id)).body)
    end

    def config
      @configuration ||= EtlConfiguration.find_by_name('notary_extraction')
    end


    def is_acceptable?(document)
      document.xpath("//table[@class='NuDetailTable']").present?
    end

    def strip_name(name)
      name.downcase.gsub(/judr.|mgr.|notársky|úrad/, '').strip
    end

    def digest(doc)
      employees = []
      doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']//div[@class='TableFontItem']/table[@class='NuDetailTable']/tr").each do |employee|
        next if employee.xpath('.//td[1]').inner_text =~ /Meno|Deň|Pondelok|Utorok|Streda|Štvrtok|Piatok/
        employee_name = employee.xpath('.//td[1]').inner_text

        employees << {
          :first_name => strip_name(employee_name).split.first.titleize,
          :last_name => strip_name(employee_name).split[1].titleize,
          :title => (employee_name.downcase.match(/judr.|mgr./)[1] rescue nil),
          :date_start => employee.xpath('.//td[2]').inner_text.strip,
          :date_end => employee.xpath('.//td[3]').inner_text.strip,
          :languages => employee.xpath('.//td[4]').inner_text.strip
        }
      end
      name, form, street, city, zip = nil, nil, nil, nil, nil
      detail_table = doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr")

      detail_table.each do |table_row|
        name = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip.gsub(/\s+/, ' ') if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Názov NÚ:/)
        form = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Forma:/)
        street = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Ulica:/)
        city = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Mesto:/)
        zip = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/PSČ:/)
      end

      if zip.present?
        zip = zip.gsub(/\s+/, '')
        zip = "#{zip[0..2]} #{zip[3..4]}"
      end

      return nil if name.downcase.match(/skuska|test|testovanie/)

      match = name.match(/(?<drop_name>NU\d+)|((Notársk(y|ý|&|a)(\s|,)?((ú|Ú)rad|kancelária)(\s([^\s,]+\s)?-)?)|((V|v)ysunuté(\s|,)?pracovisko)|(N(Ú|U)))?[,]?[\s]?(JUDr\.|Mgr\.|notára|notárky)?-?[\s,]?(?<name>[^\s,]+([\s,]+[^\s,]+)?)((\s|,)(JUDr\.|Mgr\.))?/)

      return nil if match[:drop_name].present?

      matched_name = (match[:name] rescue nil)

      if matched_name.blank?
        # TODO: add a flag that sais this is probably a bull* record
        matched_name = name
      end
      {
        :name => matched_name.gsub(/,/, ''),
        :form => form,
        :street => street,
        :city => city,
        :zip => zip,
        :doc_id => id,
        :url => document_url(id),
        :ds_notary_employees_attributes => employees
      }
    end

    def save(notari_hash)
      if notari_hash.present?
        current_record = Kernel::DsNotary.find_by_doc_id(notari_hash[:doc_id])

        notari_hash[:ds_notary_employees] = create_notrary_employees(notari_hash.delete(:ds_notary_employees_attributes))

        if current_record.present?
          current_record.update_attributes(notari_hash)
        else
          Kernel::DsNotary.create(notari_hash)
        end
      end
    end

    def create_notrary_employees(notary_employees)
      notary_employees.map do |notary_employee_hash|
        Kernel::DsNotaryEmployee.find_or_create_by_first_name_and_last_name_and_title_and_date_start_and_date_end_and_languages(
          notary_employee_hash[:first_name],
          notary_employee_hash[:last_name],
          notary_employee_hash[:title],
          notary_employee_hash[:date_start],
          notary_employee_hash[:date_end],
          notary_employee_hash[:languages]
        )
      end
    end

    def enque_job(document_id)
      Delayed::Job.enqueue Etl::NotarExtraction.new(id+1, config.batch_limit, document_id)
    end

    def self.activate_docs
      Kernel::DsNotary.update_all(record_status: 'suspended')

      active_docs = get_active_docs
      docs_to_activate = Kernel::DsNotary.where(doc_id: active_docs)

      docs_to_activate.update_all(record_status: 'published')

      Kernel::DsNotaryEmployee.update_all(record_status: 'suspended')
      emp_ids_to_activate = Dataset::DcRelation.
        where(
          relatable_left_type: 'Kernel::DsNotaryEmployee',
          relatable_right_type: 'Kernel::DsNotary',
          relatable_right_id: docs_to_activate.map(&:_record_id)
        ).
        select(:relatable_left_id).
        map(&:relatable_left_id)

      Kernel::DsNotaryEmployee.
        where(_record_id: emp_ids_to_activate).
        update_all(record_status: 'published')

      activated_docs = docs_to_activate.select(:doc_id).map{ |d| d.doc_id.to_s }
      active_docs - activated_docs
    end

    def self.get_active_docs
      id = 1
      active_docs = []
      last_doc = nil
      begin
        doc = download_page(id, last_doc)
        active_docs << parse_for_ids(doc)
        last_doc = doc
        id += 1
      end while doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr[12]/td/table/tr/td[11]/a").inner_text.match(/\.\.\./) || doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr[12]/td/table/tr/td[12]/a").inner_text.match(/\.\.\./) ||
      doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr[12]/td/table/tr/td[11]/a").present?
      active_docs.flatten
    end

    def self.parse_view_state_and_event_validation(doc)
      form_view_state = doc.css("input[name='__VIEWSTATE']").first.attributes['value']
      form_event_validation = doc.css("input[name='__EVENTVALIDATION']" ).first.attributes['value']
      return form_event_validation, form_view_state
    end

    def self.download_page(page_id, last_doc)
      if last_doc == nil
        doc_data = Typhoeus::Request.get list_url
        last_doc = Nokogiri::HTML(doc_data.body)
      end
      form_event_validation, form_view_state = parse_view_state_and_event_validation(last_doc)

      if page_id == 1
        doc_data = download_first_page(form_event_validation, form_view_state)
      else
        doc_data = download_other_page(page_id, form_event_validation, form_view_state)
      end
      Nokogiri::HTML( doc_data.body )
    end

    def self.download_first_page(event_validation, view_state)
      Typhoeus.post(
          'http://www.notar.sk/%C3%9Avod/Not%C3%A1rskecentr%C3%A1lneregistre/Not%C3%A1rske%C3%BArady.aspx',
          body: {
              'dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$txtOtvoreneVCase' => '00:00',
              '__EVENTTARGET' => 'dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$DataGrid1',
              '__EVENTARGUMENT' => 'Page$1',
              '__VIEWSTATE' => view_state.value,
              '__VIEWSTATEENCRYPTED' => '',
              '__EVENTVALIDATION' => event_validation.value,
              'dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$Vyhladaj.x' => '-750',
              'dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$Vyhladaj.y' => '-763'
          })
    end

    def self.download_other_page(page, event_validation, view_state)
      Typhoeus.post(
          'http://www.notar.sk/%C3%9Avod/Not%C3%A1rskecentr%C3%A1lneregistre/Not%C3%A1rske%C3%BArady.aspx',
          body: {
              'dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$txtOtvoreneVCase' => '00:00',
              '__EVENTTARGET' => 'dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$DataGrid1',
              '__EVENTARGUMENT' => "Page$#{page}",
              '__VIEWSTATE' => view_state.value,
              '__VIEWSTATEENCRYPTED' => '',
              '__EVENTVALIDATION' => event_validation.value
          })
    end

    def self.parse_for_ids(doc)
      doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr/td/a").map do |link|
        link.attributes['href'].value.match(/(?<id>\d+)$/)[:id]
      end
    end

  end
end
