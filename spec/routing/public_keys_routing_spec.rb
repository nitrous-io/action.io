require 'spec_helper'

describe PublicKeysController do
  describe 'routing' do
    specify { expect({ get:    '/public_keys'   }).to route_to controller: 'public_keys', action: 'index'  }
    specify { expect({ post:   '/public_keys'   }).to route_to controller: 'public_keys', action: 'create' }
    specify { expect({ delete: '/public_keys/1' }).to route_to controller: 'public_keys', action: 'destroy', id: '1' }

    specify { expect({ post: '/public_keys/import_github_keys' }).to route_to controller: 'public_keys', action: 'import_github_keys' }
  end
end
