require 'spec_helper'

describe HomeController do
  describe 'routing' do
    specify { expect({ get: '/' }).to route_to controller: 'home', action: 'index' }
    specify { expect({ get: '/ping' }).to route_to controller: 'home', action: 'ping' }
    specify { expect({ get: '/pricing' }).to route_to controller: 'home', action: 'pricing' }
    specify { expect({ get: '/jobs' }).to route_to controller: 'home', action: 'jobs' }
    specify { expect({ get: '/team' }).to route_to controller: 'home', action: 'team' }
    specify { expect({ get: '/chat' }).to route_to controller: 'home', action: 'chat' }
    specify { expect({ get: '/about' }).to route_to controller: 'home', action: 'about' }
    specify { expect({ get: '/enterprise' }).to route_to controller: 'home', action: 'business' }
    specify { expect({ get: '/business' }).to route_to controller: 'home', action: 'business' }
    specify { expect({ get: '/collab' }).to route_to controller: 'home', action: 'collab' }

    specify { expect({ get: '/join' }).to route_to controller: 'home', action: 'index' }
    specify { expect({ get: '/join/abcref' }).to route_to controller: 'home', action: 'index', ref: 'abcref' }
    specify { expect({ get: '/promo/buylah' }).to route_to controller: 'home', action: 'index', coupon_code: 'buylah' }
  end
end
