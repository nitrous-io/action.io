require 'spec_helper'

describe Users::SessionsController do
  describe 'routing' do
    specify { { get:    '/users/sign_in'  }.should route_to controller: 'users/sessions', action: 'new' }
    specify { { post:   '/users/sign_in'  }.should route_to controller: 'users/sessions', action: 'create' }
    specify { { delete: '/users/sign_out' }.should route_to controller: 'users/sessions', action: 'destroy' }
    specify { { get: '/users/sign_in_with_token' }.should route_to controller: 'users/sessions', action: 'create_with_sign_in_token' }
  end
end

