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

    def apt_username
      return nil if !self.boxhost.owner
      self.boxhost.owner.username
    end

    def apt_password
      return nil if !self.boxhost.owner

      app = Doorkeeper::Application.find_by_name('apt.nitrous.io')
      token = Doorkeeper::AccessToken.where(
        application_id: app.id,
        resource_owner_id: self.boxhost.owner.id,
        scopes: 'user',
      ).first_or_create!

      token.token
    end

    def hydrated_config
      raise NotImplementedError, 'Hostbuilder subclasses must implement a hydrated_config method'
    end
  end
end
