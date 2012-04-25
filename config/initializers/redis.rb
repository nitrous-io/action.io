redis_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/redis.yml")).result)[Rails.env]
if redis_config.starts_with? 'redis://'
  uri = URI.parse(redis_config)
  REDIS = Redis.new(host: uri.host, port: uri.port, password: uri.password)
else
  REDIS = Redis.new(url: redis_config)
end

