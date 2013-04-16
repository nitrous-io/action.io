rails_env = ENV['RACK_ENV'] || 'development'

worker_processes 5
timeout 30

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection if defined? ActiveRecord::Base
end
