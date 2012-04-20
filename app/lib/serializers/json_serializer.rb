module Serializers
  class JSONSerializer
    def self.dump(obj)
      ActiveSupport::JSON.encode(obj)
    end

    def self.load(json)
      ActiveSupport::JSON.decode(json)
    end
  end
end
