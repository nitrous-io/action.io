class Datadog
  def self.emit_point(event, count, tags=nil)
    client.emit_point(event, count, host: Settings.rails_host, tags: tags)
  end

  def self.client
    @client ||= Dogapi::Client.new(ENV['DATADOG_API_KEY'])
  end
end
