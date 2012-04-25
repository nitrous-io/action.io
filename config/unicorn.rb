rails_env = ENV['RACK_ENV'] || 'development'

case rails_env
  when 'production'
    worker_processes 3
  else
    worker_processes 2
end

timeout 30

