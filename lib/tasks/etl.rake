namespace :etl do
  task :vvo_extraction => :environment do
    config = EtlConfiguration.find_by_name('vvo_extraction')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::VvoExtraction.new(config.start_id, config.batch_limit,id)
    end
  end
  
  task :regis_extraction => :environment do
    config = EtlConfiguration.find_by_name('regis_extraction')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::RegisExtraction.new(config.start_id, config.batch_limit,id)
    end
  end
  
  task :vvo_loading => :environment do
    source_table = 'sta_procurements2'
    dataset_table = 'ds_procurements2'
    regis_table = 'sta_regis_main'
    staging_schema = StagingRecord.connection.current_database
    dataset_schema = DatasetRecord.connection.current_database

    load = "INSERT INTO #{dataset_schema}.#{dataset_table} 
            (id, year, bulletin_id, procurement_id, customer_ico, customer_company_name, customer_company_address, customer_company_town, supplier_ico, supplier_company_name, supplier_region, supplier_company_address, supplier_company_town, procurement_subject, price, currency, is_vat_included, customer_ico_evidence, supplier_ico_evidence, subject_evidence, price_evidence, procurement_type_id, document_id, source_url, created_at, is_price_part_of_range, customer_name, note, record_status)
            SELECT
                m.id,
                year,
                bulletin_id,
                procurement_id,
                customer_ico,
                rcust.name customer_company_name,
                substring_index(rcust.address, ',', 1) as customer_company_address,
                substring(substring_index(rcust.address, ',', -1), 9) as customer_company_town,
                supplier_ico,
                rsupp.name supplier_company_name,
                rsupp.region supplier_region,
                substring_index(rsupp.address, ',', 1) as supplier_company_address,
                substring(substring_index(rsupp.address, ',', -1), 9) as supplier_company_town,
                procurement_subject,
                price,
                currency,
                is_vat_included,
                customer_ico_evidence,
                supplier_ico_evidence,
                subject_evidence,
                price_evidence,
                procurement_type_id,
                document_id,
                m.source_url,
                m.date_created,
                is_price_part_of_range,
                customer_name,
                note,
                'loaded' record_status
            FROM #{staging_schema}.#{source_table} m
            LEFT JOIN #{staging_schema}.#{regis_table} rcust ON rcust.ico = customer_ico
            LEFT JOIN #{staging_schema}.#{regis_table} rsupp ON rsupp.ico = supplier_ico
            WHERE m.etl_loaded_date IS NULL"
  
    StagingRecord.connection.execute(load)
    
    procurement_model = Class.new StagingRecord
    procurement_model.set_table_name "sta_procurements2"
    procurement_model.update_all :etl_loaded_date => Time.now
  end
  
  task :regis_loading => :environment do
    
  end
end
