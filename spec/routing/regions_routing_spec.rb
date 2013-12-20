require 'spec_helper'

describe RegionsController do
  describe 'routing' do
    specify { expect({ get: '/regions' }).to route_to controller: 'regions', action: 'index' }
    specify { expect({ get: '/regions/closest' }).to route_to controller: 'regions', action: 'closest' }
    specify { expect({ get: '/regions/fetch_closest' }).to route_to controller: 'regions', action: 'fetch_closest' }
  end
end

