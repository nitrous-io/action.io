require 'spec_helper'

describe Oauth::AuthorizationsController do
  describe 'routing' do
    specify { expect({    get: '/oauth/authorize/c0d3' }).to route_to controller: 'oauth/authorizations', action: 'show', code: 'c0d3' }
    specify { expect({    get: '/oauth/authorize'      }).to route_to controller: 'oauth/authorizations', action: 'new' }
    specify { expect({   post: '/oauth/authorize'      }).to route_to controller: 'oauth/authorizations', action: 'create' }
    specify { expect({ delete: '/oauth/authorize'      }).to route_to controller: 'oauth/authorizations', action: 'destroy' }
  end
end
