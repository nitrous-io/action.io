require 'spec_helper'

describe Oauth::TokenInfoController do
  describe 'routing' do
    specify { expect({ get: '/oauth/token/info' }).to route_to controller: 'oauth/token_info', action: 'show' }
  end
end
