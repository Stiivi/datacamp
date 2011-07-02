module Etl
  class Extraction < Struct.new(:start_id, :batch_limit, :id)
    
    def download(id)
      Nokogiri::HTML(Typhoeus::Request.get(document_url(id)).body.encode('utf-8', 'cp1250'))
    end
    
    def update_last_processed
      config.update_attribute(:last_processed_id, id) if config.last_processed_id.nil? || id > config.last_processed_id
    end
    
    def perform
      document = download(id)
      if is_acceptable?(document)
        procurement_hash = digest(document)
        save(procurement_hash)
        update_last_processed
      end
    end
    
    def after(job)
      if id == (start_id + batch_limit)
        if config.last_processed_id > start_id
          ((id+1)..(id+1+config.batch_limit)).each do |i|
            enque_job(i)
          end
        else
          config.update_attribute(:start_id, config.last_processed_id+1)
        end
      end
    end
    
  end
end