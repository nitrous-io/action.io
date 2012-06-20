require 'spec_helper'

describe HomeController do
  describe 'routing' do
    specify { { get: '/' }.should route_to controller: 'home', action: 'index' }
    specify { { get: '/ping' }.should route_to controller: 'home', action: 'ping' }
    specify { { get: '/pricing' }.should route_to controller: 'home', action: 'pricing' }
    specify { { get: '/tnw' }.should route_to controller: 'home', action: 'tnw' }
    specify { { get: '/rww' }.should route_to controller: 'home', action: 'rww' }
    specify { { get: '/arstechnica' }.should route_to controller: 'home', action: 'ars' }
  end
end
