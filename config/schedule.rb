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

every 1.day, :at => '1:30 pm' do
  command "cd /home/gusto/projects/rahnama_dot_com_scraper && thor rahnama:scrap_ads --browser=plain"
end

every 1.day, :at => '2:30 pm' do
  command "cd /home/gusto/projects/rahnama_dot_com_scraper && thor rahnama:send_daily_digest"
end