redis_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/redis.yml")).result)[Rails.env]
uri = URI.parse(redis_config)
options = {}
options[:host]     ||= uri.host
options[:port]     ||= uri.port
options[:password] ||= uri.password
options[:db]       ||= uri.path[1..-1].to_i
REDIS = Redis.new(options)

