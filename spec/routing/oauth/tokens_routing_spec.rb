describe Oauth::TokensController do
  describe 'routing' do
    specify { { post: '/oauth/token' }.should route_to controller: 'oauth/tokens', action: 'create' }
  end
end
