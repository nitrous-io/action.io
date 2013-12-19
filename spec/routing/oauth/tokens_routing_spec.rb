describe Oauth::TokensController do
  describe 'routing' do
    specify { expect({ post: '/oauth/token' }).to route_to controller: 'oauth/tokens', action: 'create' }
  end
end
