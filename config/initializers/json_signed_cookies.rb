# Monkey patch CookieJar to use JSON instead of Marshal.
# Look at the ActionDispatch::Cookies source if you ever need to change this.
module ActionDispatch
  class Cookies
    module VerifyAndUpgradeLegacySignedMessage
      def initialize(*args)
        super
        @legacy_verifier = ActiveSupport::MessageVerifier.new(@options[:secret_token], serializer: JSON)
      end
    end
  end
end

# JSON serialization for ActionDispatch::Flash::FlashHash.
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
