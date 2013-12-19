require 'spec_helper'

describe Users::SessionsController do
  describe 'routing' do
    specify { expect({ get:    '/users/sign_in'  }).to route_to controller: 'users/sessions', action: 'new' }
    specify { expect({ post:   '/users/sign_in'  }).to route_to controller: 'users/sessions', action: 'create' }
    specify { expect({ delete: '/users/sign_out' }).to route_to controller: 'users/sessions', action: 'destroy' }
    specify { expect({ get: '/users/sign_in_with_token' }).to route_to controller: 'users/sessions', action: 'create_with_sign_in_token' }
  end
end

