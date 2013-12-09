rails_env = ENV['RACK_ENV'] || 'development'
domain = ENV['RAILS_DOMAIN']

worker_processes 3
if domain =~ /n2ostaging.com/
  timeout 15
else
  timeout 30
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection if defined? ActiveRecord::Base
end
