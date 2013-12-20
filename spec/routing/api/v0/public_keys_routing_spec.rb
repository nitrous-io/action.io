require 'spec_helper'

describe Api::V0::PublicKeysController do
  describe 'routing' do
    specify { expect({    get: '/api/v0/public_keys'   }).to route_to controller: 'api/v0/public_keys', action: 'index',   format: 'json' }
    specify { expect({   post: '/api/v0/public_keys'   }).to route_to controller: 'api/v0/public_keys', action: 'create',  format: 'json' }
    specify { expect({ delete: '/api/v0/public_keys/1' }).to route_to controller: 'api/v0/public_keys', action: 'destroy', format: 'json', id: '1'}
  end
end
