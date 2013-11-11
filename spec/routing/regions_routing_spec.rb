require 'spec_helper'

describe RegionsController do
  describe 'routing' do
    specify { { get: '/regions' }.should route_to controller: 'regions', action: 'index' }
    specify { { get: '/regions/closest' }.should route_to controller: 'regions', action: 'closest' }
  end
end

