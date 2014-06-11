module Hostbuilder
  class Base
    attr_reader :boxhost
    attr_reader :provider

    def initialize(boxhost)
      @boxhost = boxhost
    end

    def create(webhook=nil)
      config = self.boxhost.boxhost_provider_template.config

      uri = "#{HOSTBUILDER_URI}/host"
      query = {
        provider: self.provider,
        webhook: webhook,
        config: JSON.generate(self.hydrated_config)
      }

      unless Rails.env.test?
        puts "Hostbuilder/#{self.provider} HTTP POST to #{uri} for boxhost ID #{self.boxhost.id}"
        puts "  Query: #{query.inspect}"
      end

      result = self.class.post uri, query: query
      render(result)
    end

    def hydrated_config
      raise NotImplementedError, 'Hostbuilder subclasses must implement a hydrated_config method'
    end
  end
end
