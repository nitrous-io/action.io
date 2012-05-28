Resque.redis = REDIS
Resque.redis.namespace = 'resque:aio'

unless Rails.env.development?
  Resque::Server.use Rack::Auth::Basic do |username, password|
    username == 'aio' && password == (ENV['RESQUE_PASSWORD'] || 'rsR3AVbKpRifwAHU9CxGLXRfrUnTjqgn')
  end
end

