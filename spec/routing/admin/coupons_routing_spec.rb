require 'spec_helper'

describe Admin::CouponsController do
  describe 'routing' do
    specify { expect(get: '/admin/coupons').to route_to controller: 'admin/coupons', action: 'index' }
    specify { expect(get: '/admin/coupons/new').to route_to controller: 'admin/coupons', action: 'new' }
    specify { expect(post: '/admin/coupons').to route_to controller: 'admin/coupons', action: 'create' }
    specify { expect(put: '/admin/coupons/1/activate').to route_to controller: 'admin/coupons', action: 'activate', id: '1' }
    specify { expect(put: '/admin/coupons/1/deactivate').to route_to controller: 'admin/coupons', action: 'deactivate', id: '1' }
  end
end
