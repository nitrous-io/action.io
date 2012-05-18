# Monkey patch SignedCookieJar to use JSONSerializer instead of Marshal
module ActionDispatch
  class Cookies
    class SignedCookieJar
      def initialize_with_json_verifier(parent_jar, secret)
        initialize_without_json_verifier(parent_jar, secret)
        @verifier.instance_variable_set(:@serializer, Serializers::JSONSerializer)
      end

      alias_method_chain :initialize, :json_verifier
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
