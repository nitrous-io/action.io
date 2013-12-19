require 'spec_helper'

describe Oauth::AuthorizedApplicationsController do
  describe 'routing' do
    specify { expect({    get: '/oauth/authorized_applications'   }).to route_to controller: 'oauth/authorized_applications', action: 'index' }
    specify { expect({ delete: '/oauth/authorized_applications/1' }).to route_to controller: 'oauth/authorized_applications', action: 'destroy', id: '1' }
  end
end
