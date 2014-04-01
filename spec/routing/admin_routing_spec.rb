require 'spec_helper'

describe Admin::CouponsController do
  describe 'routing' do
    specify { expect(get: '/admin').to route_to controller: 'admin', action: 'index' }
  end
end
