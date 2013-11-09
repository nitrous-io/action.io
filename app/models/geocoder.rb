# Maps IP address to location.
#
# Someday when your yak gets really hairy, we can add some bling like
# making the data source configurable (e.g. Maxmind, geocoder.ca) via
# something like Geocoder.configure(options).
module Geocoder
  extend self

  def search(ip)
    return nil if ip.blank?

    response = HTTParty.get("http://www.telize.com/geoip/#{ip}", timeout: 2)
    return nil if response.code != 200

    Geocoder::Location.new(response.parsed_response)
  rescue Timeout::Error => e
    nil
  end

  class Location
    attr_accessor :data

    def initialize(data)
      @data = data
    end

    def self.attrs
      %w(city country country_code continent_code latitude longitude)
    end

    attrs.each do |attr|
      define_method attr do
        @data[attr]
      end
    end
  end

end
