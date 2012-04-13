require 'spec_helper'

describe PublicKeysController do
  describe 'routing' do
    specify { { get:    '/public_keys'   }.should route_to controller: 'public_keys', action: 'index'  }
    specify { { post:   '/public_keys'   }.should route_to controller: 'public_keys', action: 'create' }
    specify { { get:    '/public_keys/1' }.should route_to controller: 'public_keys', action: 'show',    id: '1' }
    specify { { put:    '/public_keys/1' }.should route_to controller: 'public_keys', action: 'update',  id: '1' }
    specify { { delete: '/public_keys/1' }.should route_to controller: 'public_keys', action: 'destroy', id: '1' }
  end
end
