require 'spec_helper'

describe Admin::BannedUsersController do
  describe 'routing' do
    specify { expect(get: '/admin/banned_users').to route_to controller: 'admin/banned_users', action: 'index' }
  end
end
