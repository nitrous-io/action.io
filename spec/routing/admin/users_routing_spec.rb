require 'spec_helper'

describe Admin::UsersController do
  describe 'routing' do
    specify { expect(get: '/admin/users').to route_to controller: 'admin/users', action: 'index' }
    specify { expect(post: '/admin/users/1/ban').to route_to controller: 'admin/users', action: 'ban', id: '1' }
    specify { expect(post: '/admin/users/1/switch').to route_to controller: 'admin/users', action: 'switch', id: '1' }
    specify { expect(get: '/admin/users/1/edit').to route_to controller: 'admin/users', action: 'edit', id: '1' }
    specify { expect(put: '/admin/users/1').to route_to controller: 'admin/users', action: 'update', id: '1' }
    specify { expect(get: '/admin/users/1/fill_n2o').to route_to controller: 'admin/users', action: 'fill_n2o', id: '1' }
    specify { expect(post: '/admin/users/1/commit_fill_n2o').to route_to controller: 'admin/users', action: 'commit_fill_n2o', id: '1' }
    specify { expect(post: '/admin/users/1/toggle_private_snapshots').to route_to controller: 'admin/users', action: 'toggle_private_snapshots', id: '1' }
  end
end
