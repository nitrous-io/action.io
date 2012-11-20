require 'spec_helper'

describe Oauth::AuthorizationsController do
  describe 'routing' do
    specify { {    get: '/oauth/authorize/c0d3' }.should route_to controller: 'oauth/authorizations', action: 'show', code: 'c0d3' }
    specify { {    get: '/oauth/authorize'      }.should route_to controller: 'oauth/authorizations', action: 'new' }
    specify { {   post: '/oauth/authorize'      }.should route_to controller: 'oauth/authorizations', action: 'create' }
    specify { { delete: '/oauth/authorize'      }.should route_to controller: 'oauth/authorizations', action: 'destroy' }
  end
end
