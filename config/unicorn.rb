rails_env = ENV['RACK_ENV'] || 'development'
domain = ENV['RAILS_DOMAIN']

listen '/tmp/nginx.socket'
before_fork do |server, worker|
  FileUtils.touch('/tmp/app-initialized')
end

worker_processes 3
timeout 30

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection if defined? ActiveRecord::Base
end
