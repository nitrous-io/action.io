module Hostbuilder
  class DigitalOcean < Hostbuilder::Base
    module Region
      ALL = [
        NYC1 = 1,
        AMS1 = 2,
        SFO1 = 3,
        NYC2 = 4,
        AMS2 = 5,
        SGP1 = 6,
      ]
    end

    module Size
      ALL = [
        S_512MB = 66,
        S_1GB = 63,
        S_2GB = 62,
        S_4GB = 64,
        S_8GB = 65,
        S_16GB = 61,
      ]
    end

    include HTTParty
    format :json

    # FIXME This should simply rely on the impl in Hostbuilder::Base.
    # The DigitalOcean impl should simply fill in the variables.
    def create(webhook=nil)
      config = self.boxhost.boxhost_provider_template.config

      uri = "#{HOSTBUILDER_URI}/host"
      query = {
        provider: 'digitalocean',
        webhook: webhook,
        config: JSON.generate({
          name: self.boxhost.name,
          image_id: config['image_id'].to_s,   # Convert these 3 IDs to strings
          region_id: config['region_id'].to_s, # because hostbuilder requires
          size_id: config['size_id'].to_s,     # strings.
          public_keys: self.boxhost.public_keys,
        })
      }

      unless Rails.env.test?
        puts "Hostbuilder::DigitalOcean HTTP POST to #{uri} for boxhost ID #{self.boxhost.id}"
        puts "  Query: #{query.inspect}"
      end

      result = self.class.post uri, query: query
      render(result)
    end

    private
    def render(result)
      if result['status'] == 'ok'
        return true
      else
        raise HostbuilderError, result.inspect
      end
    end
  end
end
