require 'spec_helper'

describe DevelopController do
  specify { expect(get: '/develop').to route_to controller: 'develop', action: 'index' }
  specify { expect(get: '/develop/embed').to route_to controller: 'develop', action: 'embed' }
end
