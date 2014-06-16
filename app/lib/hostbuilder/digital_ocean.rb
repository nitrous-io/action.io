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

    def provider
      'digitalocean'
    end

    def hydrated_config
      owner = self.boxhost.owner
      config = self.boxhost.boxhost_provider_template.config

      {
        name: self.boxhost.name,
        image_id: config['image_id'].to_s,        # Convert these IDs to strings
        region_id: config['host_region_id'].to_s, # because hostbuilder requires
        size_id: config['size_id'].to_s,          # strings.
        public_keys: self.boxhost.public_keys,
        apt_username: self.apt_username,
        apt_password: self.apt_password,
        apt_dist: 'trusty',             # TODO Maybe add these 2 fields as
        apt_location: 'apt.nitrous.io', # columns in Boxhost.
      }
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
