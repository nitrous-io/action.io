class Datadog
  def self.emit(event, count)
    client.emit(event, count, host: Settings.rails_host)
  end

  def self.client
    @client ||= Dogapi::Client.new(ENV['DATADOG_API_KEY'])
  end
end
