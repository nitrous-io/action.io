require 'spec_helper'

describe AddonsController do
  describe 'routing' do
    specify { { get: '/addons' }.should route_to controller: 'addons', action: 'index', format: 'json' }
  end
end
