require 'spec_helper'

describe HomeController do
  describe 'routing' do
    specify { { get: '/' }.should route_to controller: 'home', action: 'index' }
    specify { { get: '/ping' }.should route_to controller: 'home', action: 'ping' }
    specify { { get: '/pricing' }.should route_to controller: 'home', action: 'pricing' }
    specify { { get: '/jobs' }.should route_to controller: 'home', action: 'jobs' }
    specify { { get: '/team' }.should route_to controller: 'home', action: 'team' }
    specify { { get: '/chat' }.should route_to controller: 'home', action: 'chat' }
    specify { { get: '/about' }.should route_to controller: 'home', action: 'about' }
    specify { { get: '/enterprise' }.should route_to controller: 'home', action: 'enterprise' }

    specify { { get: '/join' }.should route_to controller: 'home', action: 'index' }
    specify { { get: '/join/abcref' }.should route_to controller: 'home', action: 'index', ref: 'abcref' }
  end
end
