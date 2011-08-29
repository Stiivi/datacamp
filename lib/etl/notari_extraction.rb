# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class NotariExtraction < Etl::Extraction
    def document_url(id)
      URI.encode "http://www.notar.sk/Úvod/Notárskecentrálneregistre/Notárskeúrady/Notárskeúradydetail.aspx?id=#{id}"
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
      {
        :name => doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr[1]/td[2]").inner_text.strip,
        :form => doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr[2]/td[2]").inner_text.strip,
        :street => doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr[3]/td[2]").inner_text.strip,
        :city => doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr[4]/td[2]").inner_text.strip,
        :zip => doc.xpath("//div[@id='dnn_ctr730_ModuleContent']/div[@class='TableFontItem']/table[@class='NuDetailTable']/tr[5]/td[2]").inner_text.strip,
        :employees => employees,
        :doc_id => id,
        :url => document_url(id)
      }
    end

    def save(notari_hash)
      hash_to_save = notari_hash.clone
      employees = hash_to_save.delete(:employees)
      
      employees.each do |employee|
        Staging::StaNotari.create(employee.merge(hash_to_save))
      end
    end
    
    def enque_job(document_id)
      Delayed::Job.enqueue Etl::NotariExtraction.new(id+1, config.batch_limit, document_id)
    end

  end
end
