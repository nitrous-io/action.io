require 'spec_helper'

describe UsersController do
  describe 'routing' do
    specify { { put: '/users/intro_seen' }.should route_to controller: 'users', action: 'intro_seen', format: 'json' }
  end
end
