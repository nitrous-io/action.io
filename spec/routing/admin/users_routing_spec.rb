require 'spec_helper'

describe Admin::UsersController do
  describe 'routing' do
    specify { { post: '/admin/users/switch_user' }.should route_to controller: 'admin/users', action: 'switch_user' }
  end
end
