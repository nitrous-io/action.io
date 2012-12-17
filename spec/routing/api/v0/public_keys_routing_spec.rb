require 'spec_helper'

describe Api::V0::PublicKeysController do
  describe 'routing' do
    specify { {    get: '/api/v0/public_keys'   }.should route_to controller: 'api/v0/public_keys', action: 'index',   format: 'json' }
    specify { {   post: '/api/v0/public_keys'   }.should route_to controller: 'api/v0/public_keys', action: 'create',  format: 'json' }
    specify { { delete: '/api/v0/public_keys/1' }.should route_to controller: 'api/v0/public_keys', action: 'destroy', format: 'json', id: '1'}
  end
end
