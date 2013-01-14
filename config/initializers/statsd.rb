# Required ENV variables
# - STATSD_HOST: host of the statsd server i.e. 127.0.0.1
# - STATSD_HOST: port of the statsd server i.e. 8125
# - STATSD_ENV: current env of the server i.e. production|staging|development
METRICS = Statsd.new ENV['STATSD_HOST'], ENV['STATSD_PORT']
METRICS.namespace = "web.#{ENV['STATSD_ENV']}"
