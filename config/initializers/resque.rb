redis_config = YAML.load_file("#{Rails.root}/config/redis.yml")
Resque.redis = redis_config[Rails.env]
Resque.redis.namespace = 'resque:aio'

Resque::Server.use Rack::Auth::Basic do |username, password|
  username == 'aio' && password == 'rsR3AVbKpRifwAHU9CxGLXRfrUnTjqgn'
end

