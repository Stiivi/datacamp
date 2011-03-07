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
  rake "etl:vvo_extraction"
end

every 1.day, :at => '2:30 am' do
  rake "etl:regis_loading"
  rake "etl:vvo_loading"
end

every 1.day, :at => '4:30 am' do
  rake "db:dump"
end

every 1.day, :at => '5:05 am' do
  rake "ts:rebuild"
end