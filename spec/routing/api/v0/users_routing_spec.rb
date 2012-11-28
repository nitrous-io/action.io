require 'spec_helper'

describe Api::V0::UsersController do
  describe 'routing' do
    specify { { get: '/api/v0/user' }.should route_to controller: 'api/v0/users', action: 'show', format: 'json' }
  end
end
