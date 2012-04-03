require 'spec_helper'

describe Users::OmniauthCallbacksController do
  describe 'routing' do
    specify { { get: '/users/auth/github' }.should route_to controller: 'users/omniauth_callbacks', action: 'passthru', provider: 'github' }
    specify { { get: '/users/auth/github/callback' }.should route_to controller: 'users/omniauth_callbacks', action: 'github' }
  end
end

