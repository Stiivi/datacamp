# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class NotarExtraction < Etl::Extraction
    def document_url(id)
      URI.encode "http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady/Notárskeúradydetail.aspx?id=#{id}"
    end
    
    def list_url(id)
      URI.encode "http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady.aspx?__EVENTTARGET=dnn$ctr729$ViewSimpleWrapper$SimpleWrapperControl_729$DataGrid1&__EVENTARGUMENT=Page$#{id}"
    end
    
    def download(id)
      Nokogiri::HTML(Typhoeus::Request.get(document_url(id)).body)
    end
    
    def config
      @configuration ||= EtlConfiguration.find_by_name('notari_extraction')
    end
    
    
    def is_acceptable?(document)
      document.xpath("//table[@class='NuDetailTable']").present?
    end
    
    
    def digest(doc)
      employees = []
      doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr[6]/td[2]/div/table/tr").each do |employee|
        next if employee.xpath('.//td[1]').inner_text =~ /Meno/
        employees << {
          :worker_name => employee.xpath('.//td[1]').inner_text.strip,
          :date_start => employee.xpath('.//td[2]').inner_text.strip,
          :date_end => employee.xpath('.//td[3]').inner_text.strip,
          :languages => employee.xpath('.//td[4]').inner_text.strip
        }
      end
      name, form, street, city, zip = nil, nil, nil, nil, nil
      detail_table = doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr")
      detail_table.each do |table_row|
        name = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Názov NÚ:/)
        form = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Forma:/)
        street = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Ulica:/)
        city = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/Mesto:/)
        zip = table_row.xpath(".//td[@class='DrazbyControlItem460']").inner_text.strip if table_row.xpath(".//td[@class='DrazbyLabelItem180']").inner_text.match(/PSČ:/)
      end
      {
        :name => name,
        :form => form,
        :street => street,
        :city => city,
        :zip => zip,
        :doc_id => id,
        :url => document_url(id),
        :active => false
      }
    end

    def save(notari_hash)
      notar_name = notari_hash[:name].downcase.gsub(/mgr.|judr./, '').strip
      current_record = Staging::StaNotar.where('name like ?', "%#{notar_name}%").first
      if current_record.present?
        current_record.update_attributes(notari_hash)
      else
        Staging::StaNotar.create(notari_hash)
      end
    end
    
    def enque_job(document_id)
      Delayed::Job.enqueue Etl::NotarExtraction.new(id+1, config.batch_limit, document_id)
    end
    
    def activate_docs
      Staging::StaNotar.update_all(active: true, doc_id: get_active_docs)
    end
    
    def get_active_docs
      id = 1
      active_docs = []
      begin
        doc_data = Typhoeus::Request.get list_url(id)
        doc = Nokogiri::HTML( doc_data.body )
        active_docs << parse_for_ids(doc)
        id += 1
      end while doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr[12]/td/table/tr/td[11]/a").inner_text.match(/\.\.\./) || doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr[12]/td/table/tr/td[12]/a").inner_text.match(/\.\.\./) ||
      doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr[12]/td/table/tr/td[11]/a").present?
      active_docs.flatten
    end
    
    def parse_for_ids(doc)
      doc.xpath("//table[@id='dnn_ctr729_ViewSimpleWrapper_SimpleWrapperControl_729_DataGrid1']/tr/td/a").map do |link|
        link.attributes['href'].value.match(/(?<id>\d+)$/)[:id]
      end
    end

  end
end
