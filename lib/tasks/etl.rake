namespace :etl do

  # Foundations
  desc 'Download foundations'
  task :foundation_extraction => :environment do
    Dataset::DsFoundation.update_all(record_status: 'suspended')
    Delayed::Job.enqueue Etl::FoundationPageExtraction.new
    Etl::NotarExtraction.update_last_run_time
  end

  task :vvo_extraction => :environment do
    config = EtlConfiguration.find_by_name('vvo_extraction')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::VvoExtraction.new(config.start_id, config.batch_limit,id)
    end
  end

  task vvo_update_old_source_urls: :environment do
    Etl::VvoExtraction.update_old_source_urls
  end

  task :regis_extraction => :environment do
    config = EtlConfiguration.find_by_name('regis_extraction')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::RegisExtraction.new(config.start_id, config.batch_limit,id)
    end
  end

  desc 'sends a delayed job notification email'
  task delayed_job_notification: :environment do
    failed_jobs = Delayed::Job.where('last_error is not null')
    if failed_jobs.present?
      EtlMailer.delayed_job_notification(failed_jobs).deliver
    end
  end

  desc 'Run this to download/update otvorenezmluvy'
  task :otvorenezmluvy_extraction => :environment do
    Delayed::Job.enqueue Etl::OtvorenezmluvyExtraction.new
  end

  desc 'Run this to download/update notaries'
  task :notari_extraction => :environment do
    config = EtlConfiguration.find_by_name('notary_extraction')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::NotarExtraction.new(config.start_id, config.batch_limit,id)
    end
  end

  desc 'Run this to mark active notaries'
  task notari_activate: :environment do
    activation_result = Etl::NotarExtraction.activate_docs

    EtlMailer.notari_status.deliver
    if activation_result.present?
      EtlMailer.notari_parser_problem(activation_result).deliver
    end

    Etl::NotarExtraction.update_last_run_time
  end

  desc 'Run this to download/update executors'
  task :executor_extraction => :environment do
    executor_extraction = Etl::ExekutorExtraction.new
    executor_extraction.perform

    EtlMailer.executor_status.deliver

    published_count = Kernel::DsExecutor.where(record_status: 'published').count
    elements_to_parse_count = executor_extraction.elements_to_parse_count
    if published_count != elements_to_parse_count
      EtlMailer.executor_parser_problem(published_count, elements_to_parse_count).deliver
    end

    Etl::ExekutorExtraction.update_last_run_time
  end

  desc 'Run this to download/update all lawyers from sak.sk page.'
  task lawyer_extraction: :environment do
    [
      ['https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/link/display/formular/button/close/event'],
      ['https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/link/display/formular/button/close/event'],
    ].each do |links|
      Etl::LawyerExtraction.new(links[0], links[1]).get_downloads.each{|adv| Delayed::Job.enqueue adv }
    end
  end

  task lawyer_lists: :environment do
    [
      ['https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/link/display/formular/button/close/event', 'is_suspended'],
      ['https://www.sak.sk/blox/cms/sk/sak/adv/cpp/proxy/list/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/cpp/proxy/link/display/formular/button/close/event', 'is_state'],
      ['https://www.sak.sk/blox/cms/sk/sak/adv/exoffo/proxy/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/exoffo/proxy/link/display/formular/button/close/event', 'is_exoffo'],
      ['https://www.sak.sk/blox/cms/sk/sak/adv/us/proxy/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/us/proxy/link/display/formular/button/close/event', 'is_constitution'],
      ['https://www.sak.sk/blox/cms/sk/sak/adv/av/proxy/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/av/proxy/link/display/formular/button/close/event', 'is_asylum']
    ].each do |links|
      Dataset::DsLawyer.update_all(links[2] => false)
      Dataset::DsLawyer.where(sak_id: Etl::LawyerExtraction.new(links[0], links[1]).get_ids_from_downloads).update_all(links[2] => true)
    end

    EtlMailer.lawyer_status.deliver

    # advokati
    active_downloads = [
      ['https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/list/list/formular/picker/event/page//', 'https://www.sak.sk/blox/cms/sk/sak/adv/vyhladanie/proxy/link/display/formular/button/close/event'],
      ['https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/list/formular/picker/event/page/', 'https://www.sak.sk/blox/cms/sk/sak/adv/stop/proxy/link/display/formular/button/close/event'],
    ].map do |links|
      Etl::LawyerExtraction.new(links[0], links[1]).get_downloads
    end.flatten
    active_ids = Etl::LawyerExtraction.map_ids(active_downloads)

    Dataset::DsLawyer.update_all(record_status: 'suspended')
    active_lawyers = Dataset::DsLawyer.where(sak_id: active_ids)
    active_lawyers.update_all(record_status: 'published')
    not_downloaded = active_ids.map{|ai| ai.to_s} - active_lawyers.select(:sak_id).map{|l| l.sak_id.to_s}
    not_downloaded_downloads = active_downloads.select{|ad| not_downloaded.include?(ad.parse_id.to_s) }
    if not_downloaded_downloads.present?
      EtlMailer.lawyer_parser_problem(not_downloaded_downloads).deliver
    end

    #spolocenstva
    active_downloads = Etl::LawyerPartnershipExtraction.new( 'https://www.sak.sk/blox/cms/sk/sak/adv/osp/proxy/list/list/formular/picker/event/page/',
                                          'https://www.sak.sk/blox/cms/sk/sak/adv/osp/proxy/link/display/spolocnost/button/close/event').get_downloads
    active_ids = Etl::LawyerPartnershipExtraction.map_ids(active_downloads)
    Dataset::DsLawyerPartnership.update_all(record_status: 'suspended')
    active_lawyer_partnerships = Dataset::DsLawyerPartnership.where(sak_id: active_ids)
    active_lawyer_partnerships.update_all(record_status: 'published')
    not_downloaded = active_ids.map{|ai| ai.to_s} - active_lawyer_partnerships.select(:sak_id).map{|l| l.sak_id.to_s}
    not_downloaded_downloads = active_downloads.select{|ad| not_downloaded.include?(ad.parse_id.to_s) }
    if not_downloaded_downloads.present?
      EtlMailer.lawyer_partnerships_parser_problem(not_downloaded_downloads).deliver
    end

    #koncipienti
    active_downloads = Etl::LawyerAssociateExtraction.new( 'https://www.sak.sk/blox/cms/sk/sak/adv/konc/proxy/list/formular/picker/event/page/',
                                          'https://www.sak.sk/blox/cms/sk/sak/adv/konc/proxy/link/display/formular/button/close/event').get_downloads
    active_ids = Etl::LawyerAssociateExtraction.map_ids(active_downloads)
    Dataset::DsLawyerAssociate.update_all(record_status: 'suspended')
    active_lawyer_associates = Dataset::DsLawyerAssociate.where(sak_id: active_ids)
    active_lawyer_associates.update_all(record_status: 'published')
    not_downloaded = active_ids.map{|ai| ai.to_s} - active_lawyer_associates.select(:sak_id).map{|l| l.sak_id.to_s}
    not_downloaded_downloads = active_downloads.select{|ad| not_downloaded.include?(ad.parse_id.to_s) }
    if not_downloaded_downloads.present?
      EtlMailer.lawyer_associates_parser_problem(not_downloaded_downloads).deliver
    end




    Etl::LawyerExtraction.update_last_run_time
  end

  desc 'Run this to download/update all lawyer partnerships and link lawyers to them.'
  task lawyer_partnership_extraction: :environment do
    downloads = Etl::LawyerPartnershipExtraction.new( 'https://www.sak.sk/blox/cms/sk/sak/adv/osp/proxy/list/list/formular/picker/event/page/',
                                          'https://www.sak.sk/blox/cms/sk/sak/adv/osp/proxy/link/display/spolocnost/button/close/event').get_downloads
    downloads.each{|download| Delayed::Job.enqueue download }
  end

  desc 'Run this to download/update all lawyer associated and link them to lawyers and/or partnerships.'
  task lawyer_associate_extraction: :environment do
    downloads = Etl::LawyerAssociateExtraction.new( 'https://www.sak.sk/blox/cms/sk/sak/adv/konc/proxy/list/formular/picker/event/page/',
                                          'https://www.sak.sk/blox/cms/sk/sak/adv/konc/proxy/link/display/formular/button/close/event').get_downloads
    sak_ids = downloads.map{|d| d.url.match(/\d+/)[0] }
    Kernel::DsLawyerAssociate.where("sak_id NOT IN (?) and record_status!='morphed'", sak_ids).update_all(record_status: 'suspended')
    downloads.each{|download| Delayed::Job.enqueue download }
  end

  desc 'Run this last to set morphed status on suspended lawyer associates that morphed into lawyers.'
  task lawyer_associate_morph: :environment do
    Kernel::DsLawyerAssociate.where(record_status: 'suspended').find_each do |associate|
      lawyer = Kernel::DsLawyer.where(first_name: associate.first_name, last_name: associate.last_name).first
      if lawyer.present? && associate.ds_lawyers_morphed.blank?
        associate.update_attribute(:record_status, 'morphed')
        associate.ds_lawyers_morphed << lawyer
        # TODO: notify via email about autoset morphs
      end
    end
  end

  task :vvo_loading => :environment do
    source_table = 'sta_procurements'
    dataset_table = 'ds_procurements'
    regis_table = 'sta_regis_main'
    staging_schema = Staging::StagingRecord.connection.current_database
    dataset_schema = Dataset::DatasetRecord.connection.current_database

    load = "INSERT INTO #{dataset_schema}.#{dataset_table}
            (id, year, bulletin_id, procurement_id, customer_ico, customer_company_name, customer_company_address, customer_company_town, supplier_ico, supplier_company_name, supplier_region, supplier_company_address, supplier_company_town, procurement_subject, price, currency, is_vat_included, customer_ico_evidence, supplier_ico_evidence, subject_evidence, price_evidence, procurement_type_id, document_id, source_url, created_at, updated_at, is_price_part_of_range, customer_name, note, record_status)
            SELECT
                m.id,
                year,
                bulletin_id,
                procurement_id,
                customer_ico,
                ifnull(rcust.name, customer_name) as customer_company_name,
                substring_index(rcust.address, ',', 1) as customer_company_address,
                substring(substring_index(rcust.address, ',', -1), 9) as customer_company_town,
                supplier_ico,
                ifnull(rsupp.name, supplier_name) as supplier_company_name,
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
                'published' record_status
            FROM #{staging_schema}.#{source_table} m
            LEFT JOIN #{staging_schema}.#{regis_table} rcust ON rcust.ico = customer_ico
            LEFT JOIN #{staging_schema}.#{regis_table} rsupp ON rsupp.ico = supplier_ico
            WHERE m.etl_loaded_date IS NULL"

    dataset_model = DatasetDescription.find_by_identifier('procurements').dataset.dataset_record_class

    last_updated_at = dataset_model.order(:updated_at).last

    Staging::StagingRecord.connection.execute(load)
    Staging::StaProcurement.update_all :etl_loaded_date => Time.now

    records_with_error = dataset_model.where("(#{dataset_table}.customer_company_name IS NULL OR #{dataset_table}.supplier_company_name IS NULL) AND #{dataset_table}.note IS NULL AND #{dataset_table}.updated_at > ?", last_updated_at).select(:_record_id)
    records_with_note = dataset_model.where("#{dataset_table}.note IS NOT NULL AND #{dataset_table}.updated_at > ?", last_updated_at).select(:_record_id)

    EtlMailer.vvo_loading_status(records_with_error, records_with_note).deliver if records_with_error.present? || records_with_note.present

    DatasetDescription.find_by_identifier('procurements').update_attribute(:data_updated_at, Time.zone.now)
  end

  task :regis_loading => :environment do
    source_table = 'sta_regis_main'
    dataset_table = 'ds_organisations'

    staging_schema = Staging::StagingRecord.connection.current_database
    dataset_schema = Dataset::DatasetRecord.connection.current_database

    Dataset::DatasetRecord.skip_callback :update, :after, :after_update
    Dataset::TmpOrganisation = Class.new Dataset::DatasetRecord
    Dataset::TmpOrganisation.set_table_name dataset_table

    append_new_records = "INSERT INTO #{dataset_schema}.#{dataset_table}
                         (doc_id, ico, name, legal_form, legal_form_code, date_start, date_end, address, region, activity1, activity1_code, activity2, activity2_code, account_sector, account_sector_code, ownership, ownership_code, size, size_code, source_url, created_at, updated_at, created_by, record_status, name_history)
                         SELECT doc_id, ico, name,
                                 lf.text legal_form, legal_form legal_form_code,
                                 m.date_start, m.date_end,
                                 address, region,
                                 a1.text activity1, activity1 activity1_code,
                                 a2.text activity2, activity2 activity2_code,
                                 acc.text account_sector, account_sector account_sector_code,
                                 os.text ownership, ownership ownership_code,
                                 s.text size, size size_code,
                                 source_url, m.date_created, m.updated_at, 'system_loading' created_by, 'published' record_status, name_history
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
                                          s.text size, size size_code, source_url, etl_loaded_date, name_history").
                                   from("#{staging_schema}.#{source_table} as m").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_legal_form lf ON lf.id = m.legal_form").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_activity1 a1 ON a1.id = m.activity1").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_activity2 a2 ON a2.id = m.activity2").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_account_sector acc ON acc.id = m.account_sector").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_ownership os ON os.id = m.ownership").
                                   joins("LEFT JOIN #{staging_schema}.sta_regis_size s ON s.id = m.size").
                                   where('m.updated_at > m.etl_loaded_date')

    modified_records.each do |r|
      record_to_update = Dataset::TmpOrganisation.find_by_doc_id(r.doc_id)
      Staging::StaRegisMain.find_by_doc_id(r.doc_id).update_attribute(:etl_loaded_date, Time.now) if record_to_update.update_attributes(
                                                             :ico => r.ico, :name => r.name, :legal_form => r.legal_form, :legal_form_code => r.legal_form_code,
                                                             :date_start => r.date_start, :date_end => r.date_end, :address => r.address, :region => r.region, :activity1 => r.activity1,
                                                             :activity1_code => r.activity1_code, :activity2 => r.activity2, :activity2_code => r.activity2_code,
                                                             :account_sector => r.account_sector, :account_sector_code => r.account_sector_code, :ownership => r.ownership,
                                                             :ownership_code => r.ownership_code, :size => r.size, :size_code => r.size_code, name_history: r.name_history)
    end

    DatasetDescription.find_by_identifier('organisations').update_attribute(:data_updated_at, Time.zone.now)
  end


  task :regis_update => :environment do
    config = EtlConfiguration.find_by_name('regis_update')
    end_id = config.start_id + config.batch_limit
    (config.start_id..end_id).each do |id|
      Delayed::Job.enqueue Etl::RegisUpdate.new(config.start_id, config.batch_limit,id)
    end
  end

  desc 'This is needed to show records that have neglected to have a proper record_status after 6658fa9.'
  task :publish_records => :environment do
    DatasetDescription.all.each do |dataset_description|
      dataset_model = dataset_description.dataset.dataset_record_class
      neglected_records_condition = "record_status IS NULL OR record_status = 'loaded' OR record_status = 'new'"
      neglected_records_count = dataset_model.where(neglected_records_condition).count
      dataset_model.where(neglected_records_condition).update_all(:record_status => 'published')
      puts "Updated #{neglected_records_count} records in #{dataset_model.table_name}."
    end
  end
end
