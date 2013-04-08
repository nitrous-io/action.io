require 'spec_helper'

describe Admin::UsersController do
  describe 'routing' do
    specify { expect(get: '/admin/users').to route_to controller: 'admin/users', action: 'index' }
    specify { expect(post: '/admin/users/switch_user').to route_to controller: 'admin/users', action: 'switch_user' }
  end
end
