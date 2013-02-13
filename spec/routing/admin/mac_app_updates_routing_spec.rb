describe Admin::MacAppUpdatesController do
  describe 'routing' do
    specify { expect(get: '/admin/mac_app_updates').to route_to controller: 'admin/mac_app_updates', action: 'index' }
    specify { expect(get: '/admin/mac_app_updates/new').to route_to controller: 'admin/mac_app_updates', action: 'new' }
    specify { expect(post: '/admin/mac_app_updates').to route_to controller: 'admin/mac_app_updates', action: 'create' }
    specify { expect(get: '/admin/mac_app_updates/1').to route_to controller: 'admin/mac_app_updates', action: 'show', id: '1' }
    specify { expect(get: '/admin/mac_app_updates/1/edit').to route_to controller: 'admin/mac_app_updates', action: 'edit', id: '1' }
    specify { expect(put: '/admin/mac_app_updates/1').to route_to controller: 'admin/mac_app_updates', action: 'update', id: '1' }
    specify { expect(delete: '/admin/mac_app_updates/1').to route_to controller: 'admin/mac_app_updates', action: 'destroy', id: '1' }
  end
end
