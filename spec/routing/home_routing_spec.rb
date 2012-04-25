require 'spec_helper'

describe HomeController do
  describe 'routing' do
    specify { { get: '/' }.should route_to controller: 'home', action: 'index' }
    specify { { get: '/ping' }.should route_to controller: 'home', action: 'ping' }
  end
end
