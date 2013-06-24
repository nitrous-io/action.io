require 'spec_helper'

describe AuthenticationsController do
  describe 'routing' do
    specify { { get: '/authentications/1/edit' }.should route_to controller: 'authentications', action: 'edit', id: '1' }
    specify { { put: '/authentications/1' }.should route_to controller: 'authentications', action: 'update', id: '1' }
  end
end
