# -*- encoding : utf-8 -*-

require 'fileutils'

module Etl
  class RegisUpdate < RegisExtraction

    def config
      @configuration ||= EtlConfiguration.find_by_name('regis_update')
    end

    def extraction_config
      RegisExtraction.new.config
    end

    def save(procurement_hash)
      staging_element = Staging::StaRegisMain.find_by_doc_id(procurement_hash[:doc_id])
      if staging_element.present?
        if staging_element.name != procurement_hash[:name]
          name_history = staging_element.name_history || {}
          staging_element.name_history = name_history.merge(Time.current => staging_element.name)
          staging_element.name = procurement_hash[:name]
        end

        staging_element.date_end = procurement_hash[:date_end]
      end

      staging_element.save!
    end

    def after(job)
      if id == (start_id + batch_limit)
        config.update_attribute(:start_id, id+1)
        if config.last_processed_id >= extraction_config.last_processed_id
          config.update_attribute(:start_id, 0)
          config.update_attribute(:last_processed_id, 0)
        end
      end
    end
  end
end
