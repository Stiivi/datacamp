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

every 1.day, at: '9:00 am' do
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
every 1.month, :at => 'January 1th 2:00 am' do
  rake 'etl:vvo_current_bulletins_extraction'
end

every '0 2 15 1 *' do
  rake 'etl:vvo_last_bulletins_extraction'
end

every 1.month, :at => 'January 1th 6:00 am' do
  rake 'etl:vvo_bulletin_report'
end

# Vvo V2

every 1.day, at: '3:00 am' do
  rake "etl:vvo_v2_new_current_bulletins_extraction"
end

every 1.month, :at => 'January 1th 2:00 am' do
  rake 'etl:vvo_v2_current_year_bulletins_extraction'
end

every '0 2 15 1 *' do
  rake 'etl:vvo_v2_last_year_bulletins_extraction'
end

every 1.month, :at => 'January 1th 8:00 am' do
  rake 'etl:vvo_v2_last_bulletin_report'
end

every 3.month, :at => 'January 1th 8:00 am' do
  rake 'etl:vvo_v2_checker'
end

# Lawyers, notari

every 1.month, at: 'January 1th 1:00 am' do
  rake 'etl:executor_extraction'
  rake 'etl:notari_extraction'
end

every 1.month, at: 'January 2th 1:00 am' do
  rake 'etl:lawyer_extraction'
  rake 'etl:lawyer_partnership_extraction'
  rake 'etl:lawyer_associate_extraction'
end

every 1.month, at: 'January 1th 3:00 am' do
  rake 'etl:notari_activate'
end

every 1.month, at: 'January 2th 7:00 am' do # this must start after finished ^^
  rake 'etl:lawyer_associate_morph'
  rake 'etl:lawyer_lists'
end

# Otvorene zmluvy

every 1.month, at: 'January 1th 5:00 am' do
  rake 'etl:otvorenezmluvy_extraction'
end

# Foundation

every 1.month, at: 'January 1th 1:30 am' do
  rake 'etl:foundation_extraction'
end

# MZVSR

every 1.month, :at => 'January 1th 1:30 am' do
  rake 'etl:mzvsr_contracts_extraction'
end

# generate sitemap fiels

every 1.month, :at => 'January 1th 4:00 am' do
  rake 'sitemap:generate_all_files'
end

every 1.month, :at => 'January 1th 5:00 am' do
  rake 'sitemap:create_site_map'
end
