require 'spec_helper'

describe Oauth::AuthorizedApplicationsController do
  describe 'routing' do
    specify { {    get: '/oauth/authorized_applications'   }.should route_to controller: 'oauth/authorized_applications', action: 'index' }
    specify { { delete: '/oauth/authorized_applications/1' }.should route_to controller: 'oauth/authorized_applications', action: 'destroy', id: '1' }
  end
end
