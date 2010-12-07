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
end
