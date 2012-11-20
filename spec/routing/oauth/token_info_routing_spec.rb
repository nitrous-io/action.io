require 'spec_helper'

describe Oauth::TokenInfoController do
  describe 'routing' do
    specify { { get: '/oauth/token/info' }.should route_to controller: 'oauth/token_info', action: 'show' }
  end
end
