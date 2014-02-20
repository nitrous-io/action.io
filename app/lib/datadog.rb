class Datadog
  def self.emit_point(event, count, options={})
    options[:host] = Settings.rails_host
    client.emit_point(event, count, options)
  end

  def self.client
    @client ||= Dogapi::Client.new(ENV['DATADOG_API_KEY'])
  end
end
