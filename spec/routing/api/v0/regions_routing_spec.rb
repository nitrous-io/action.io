require 'spec_helper'

describe Api::V0::RegionsController do
  describe 'routing' do
    specify { expect({    get: '/api/v0/regions'   }).to route_to controller: 'api/v0/regions', action: 'index',   format: 'json' }
  end
end
