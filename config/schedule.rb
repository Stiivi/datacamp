# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 1.day, :at => '1:30 am' do
  rake "etl:regis_extraction"
  rake "etl:regis_update"
  rake "etl:vvo_extraction"
end

every 1.day, :at => '2:30 am' do
  rake "etl:regis_loading"
  rake "etl:vvo_loading"
end

# Vvo check - extract bulletins in current year
every 30.days, :at => '2:00' do
  rake 'etl:vvo_current_bulletins_extraction'
end


every 1.day, :at => '4:30 am' do
  rake "db:export"
end

every 1.day, :at => '5:05 am' do
  rake "ts:rebuild"
end

every 1.week do
  rake "users:cleanup_sessions"
end

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

every 25.days, at: '3:30 am' do
  rake 'etl:lawyer_associate_morph'
  rake 'etl:lawyer_lists'
end

every 25.days do
  rake 'etl:otvorenezmluvy_extraction'
end

every 30.days, at: '1:30 am' do
  rake 'etl:foundation_extraction'
end
