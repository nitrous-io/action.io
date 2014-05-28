module Hostbuilder
  class Base
    attr_reader :boxhost

    def initialize(boxhost)
      @boxhost = boxhost
    end
  end
end
