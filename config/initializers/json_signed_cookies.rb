# Monkey patch SignedCookieJar to use JSON instead of Marshal
# TODO: improve/check this patch whenever RAILS version changes as there might
# be a more elegant way to do this
module ActionDispatch
  class Cookies
    SignedCookieJar.class_eval do
      def initialize(parent_jar, key_generator, options={})
        @parent_jar = parent_jar
        @options = options
        secret = key_generator.generate_key(@options[:signed_cookie_salt])
        @verifier   = ActiveSupport::MessageVerifier.new(secret, serializer: JSON)
      end
    end
  end
end

# JSON serialization for ActionDispatch::Flash::FlashHash
module ActionDispatch
  class Flash
    class FlashHash
      def as_json(*)
        {
          'json_class' => self.class.name,
          'data' => {
            'used'    => @used,
            'closed'  => @closed,
            'flashes' => @flashes,
            'now'     => @now.present?
          }
        }
      end

      def to_json(*a)
        as_json.to_json(*a)
      end

      def self.json_create(o)
        hash = new
        hash.instance_variable_set(:@used,    o['data']['used'].to_set)
        hash.instance_variable_set(:@closed,  o['data']['closed'])
        hash.instance_variable_set(:@flashes, o['data']['flashes'])
        hash.now if o['data']['now']
        hash
      end
    end
  end
end
