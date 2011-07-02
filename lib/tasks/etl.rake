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
    source_table = 'sta_procurements'
    dataset_table = 'ds_procurements'
    regis_table = 'sta_regis_main'
    staging_schema = Staging::StagingRecord.connection.current_database
    dataset_schema = DatasetRecord.connection.current_database

    load = "INSERT INTO #{dataset_schema}.#{dataset_table} 
            (id, year, bulletin_id, procurement_id, customer_ico, customer_company_name, customer_company_address, customer_company_town, supplier_ico, supplier_company_name, supplier_region, supplier_company_address, supplier_company_town, procurement_subject, price, currency, is_vat_included, customer_ico_evidence, supplier_ico_evidence, subject_evidence, price_evidence, procurement_type_id, document_id, source_url, created_at, updated_at, is_price_part_of_range, customer_name, note, record_status)
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
                NOW(),
                is_price_part_of_range,
                customer_name,
                note,
                'loaded' record_status
            FROM #{staging_schema}.#{source_table} m
            LEFT JOIN #{staging_schema}.#{regis_table} rcust ON rcust.ico = customer_ico
            LEFT JOIN #{staging_schema}.#{regis_table} rsupp ON rsupp.ico = supplier_ico
            WHERE m.etl_loaded_date IS NULL"
  
    Staging::StagingRecord.connection.execute(load)
    Staging::StaProcurement.update_all :etl_loaded_date => Time.now
  end
  
  task :regis_loading => :environment do
    source_table = 'sta_regis_main'
		dataset_table = 'ds_organisations'
		
    staging_schema = Staging::StagingRecord.connection.current_database
    dataset_schema = DatasetRecord.connection.current_database
    
    DatasetRecord.skip_callback :update, :after, :after_update
    regis_ds_model = Class.new DatasetRecord
    regis_ds_model.set_table_name dataset_table
    
    append_new_records = "INSERT INTO #{dataset_schema}.#{dataset_table} 
                         (doc_id, ico, name, legal_form, legal_form_code, date_start, date_end, address, region, activity1, activity1_code, activity2, activity2_code, account_sector, account_sector_code, ownership, ownership_code, size, size_code, source_url, created_at, updated_at, created_by, record_status)
                         SELECT doc_id, ico, name,
                                 lf.text legal_form, legal_form legal_form_code,
                                 m.date_start, m.date_end,
                                 address, region,
                                 a1.text activity1, activity1 activity1_code,
                                 a2.text activity2, activity2 activity2_code,
                                 acc.text account_sector, account_sector account_sector_code,
                                 os.text ownership, ownership ownership_code,
                                 s.text size, size size_code,
                                 source_url, m.date_created, m.updated_at, 'system_loading' created_by, 'loaded' record_status
                         FROM #{staging_schema}.#{source_table} m
                         LEFT JOIN #{staging_schema}.sta_regis_legal_form lf ON lf.id = m.legal_form
                         LEFT JOIN #{staging_schema}.sta_regis_activity1 a1 ON a1.id = m.activity1
                         LEFT JOIN #{staging_schema}.sta_regis_activity2 a2 ON a2.id = m.activity2
                         LEFT JOIN #{staging_schema}.sta_regis_account_sector acc ON acc.id = m.account_sector
                         LEFT JOIN #{staging_schema}.sta_regis_ownership os ON os.id = m.ownership
                         LEFT JOIN #{staging_schema}.sta_regis_size s ON s.id = m.size
                         WHERE m.etl_loaded_date IS NULL"

    Staging::StagingRecord.connection.execute(append_new_records)
    Staging::StaRegisMain.update_all ['etl_loaded_date = ?', Time.now], ['etl_loaded_date IS NULL']

    modified_records = Staging::StaRegisMain.select("doc_id, ico, name, lf.text legal_form, legal_form legal_form_code, 
                                          m.date_start, m.date_end, address, region, a1.text activity1, activity1 activity1_code, 
                                          a2.text activity2, activity2 activity2_code, acc.text account_sector, 
                                          account_sector account_sector_code, os.text ownership, ownership ownership_code, 
                                          s.text size, size size_code, source_url, etl_loaded_date").
                                   from("#{staging_schema}.#{source_table} as m").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_legal_form lf ON lf.id = m.legal_form").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_activity1 a1 ON a1.id = m.activity1").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_activity2 a2 ON a2.id = m.activity2").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_account_sector acc ON acc.id = m.account_sector").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_ownership os ON os.id = m.ownership").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_size s ON s.id = m.size").
                                   where('m.updated_at > m.etl_loaded_date')
                               
    modified_records.each do |r|
      puts r.doc_id
      record_to_update = regis_ds_model.find_by_doc_id(r.doc_id)
      Staging::StaRegisMain.find_by_doc_id(r.doc_id).update_attribute(:etl_loaded_date, Time.now) if record_to_update.update_attributes(
                                                             :ico => r.ico, :name => r.name, :legal_form => r.legal_form, :legal_form_code => r.legal_form_code, 
                                                             :date_start => r.date_start, :date_end => r.date_end, :address => r.address, :region => r.region, :activity1 => r.activity1, 
                                                             :activity1_code => r.activity1_code, :activity2 => r.activity2, :activity2_code => r.activity2_code, 
                                                             :account_sector => r.account_sector, :account_sector_code => r.account_sector_code, :ownership => r.ownership, 
                                                             :ownership_code => r.ownership_code, :size => r.size, :size_code => r.size_code)
    end

  end
  
  
  task :regis_update => :environment do
    config = EtlConfiguration.find_by_name('regis_update')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::RegisUpdate.new(config.start_id, config.batch_limit,id)
    end
  end
end
