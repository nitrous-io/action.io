describe Admin::CouponsController do
  describe 'routing' do
    specify { expect(get: '/admin/coupons').to route_to controller: 'admin/coupons', action: 'index' }
    specify { expect(get: '/admin/coupons/new').to route_to controller: 'admin/coupons', action: 'new' }
    specify { expect(post: '/admin/coupons').to route_to controller: 'admin/coupons', action: 'create' }
    specify { expect(get: '/admin/coupons/1').to route_to controller: 'admin/coupons', action: 'show', id: '1' }
    specify { expect(delete: '/admin/coupons/1').to route_to controller: 'admin/coupons', action: 'destroy', id: '1' }
  end
end
