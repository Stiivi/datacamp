# system

every 1.day, :at => '4:30 am' do
  rake "db:export"
end

every 1.day, :at => '5:05 am' do
  rake "ts:rebuild"
end

every 1.week do
  rake "users:cleanup_sessions"
end

every 1.day, at: '7:00 am' do
  rake "etl:delayed_job_notification"
end

# Regis, vvo

every 1.day, :at => '1:30 am' do
  rake "etl:regis_extraction"
  rake "etl:regis_update"
  rake "etl:vvo_extraction"
end

# Regis, vvo

every 1.day, :at => '2:30 am' do
  rake "etl:regis_loading"
  rake "etl:vvo_loading"
end

# Vvo check - extract bulletins in current year
every 30.days, :at => '2:00' do
  rake 'etl:vvo_current_bulletins_extraction'
end

every 30.days, :at => '6:00' do
  rake 'etl:vvo_bulletin_report'
end

# Lawyers, notari

every 25.days, at: '1:00 am' do
  rake 'etl:executor_extraction'
  rake 'etl:lawyer_extraction'
  rake 'etl:lawyer_partnership_extraction'
  rake 'etl:lawyer_associate_extraction'
  rake 'etl:notari_extraction'
end

every 25.days, at: '3:00 am' do
  rake 'etl:notari_activate'
end

every 25.days, at: '5:00 am' do # this must start after finished ^^
  rake 'etl:lawyer_associate_morph'
  rake 'etl:lawyer_lists'
end

# Otvorene zmluvy

every 25.days do
  rake 'etl:otvorenezmluvy_extraction'
end

# Foundation

every 30.days, at: '1:30 am' do
  rake 'etl:foundation_extraction'
end

# MZVSR

every 30.days, :at => '1:50 am' do
  rake 'etl:mzvsr_contracts_extraction'
end

# generate sitemap fiels

every 1.month, :at => '4:00 am' do
  rake 'sitemap:generate_all_files'
end

every 1.month, :at => '5:00 am' do
  rake 'sitemap:create_site_map'
end
