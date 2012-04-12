redis_config = YAML.load_file("#{Rails.root}/config/redis.yml")
REDIS = Redis.new(url: redis_config[Rails.env])

