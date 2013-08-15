require 'spec_helper'

describe AddonsController do
  describe 'routing' do
    specify { { get: '/addons' }.should route_to controller: 'addons', action: 'index' }
    specify { { get: '/addons/mongolab' }.should route_to controller: 'addons', action: 'show', id: 'mongolab' }
  end
end
