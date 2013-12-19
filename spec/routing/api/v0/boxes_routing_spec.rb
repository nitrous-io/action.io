require 'spec_helper'

describe Api::V0::BoxesController do
  describe 'routing' do
    specify { expect({ get: '/api/v0/boxes'   }).to route_to controller: 'api/v0/boxes', action: 'index', format: 'json'  }
    specify { expect({ get: '/api/v0/boxes/1' }).to route_to controller: 'api/v0/boxes', action: 'show',  format: 'json', id: '1' }

    specify { expect({ post: '/api/v0/boxes' }).to route_to controller: 'api/v0/boxes', action: 'create',   format: 'json' }

    specify { expect({ put: '/api/v0/boxes/1/start'   }).to route_to controller: 'api/v0/boxes', action: 'start',   format: 'json', id: '1' }
    specify { expect({ put: '/api/v0/boxes/1/stop'    }).to route_to controller: 'api/v0/boxes', action: 'stop',    format: 'json', id: '1' }
    specify { expect({ put: '/api/v0/boxes/1/restart' }).to route_to controller: 'api/v0/boxes', action: 'restart', format: 'json', id: '1' }

    specify { expect({ post: '/api/v0/boxes/1/start'   }).to route_to controller: 'api/v0/boxes', action: 'start',   format: 'json', id: '1' }
    specify { expect({ post: '/api/v0/boxes/1/stop'    }).to route_to controller: 'api/v0/boxes', action: 'stop',    format: 'json', id: '1' }
    specify { expect({ post: '/api/v0/boxes/1/restart' }).to route_to controller: 'api/v0/boxes', action: 'restart', format: 'json', id: '1' }

    specify { expect({ delete: '/api/v0/boxes/1' }).to route_to controller: 'api/v0/boxes', action: 'destroy', format: 'json', id: '1' }
    specify { expect({    put: '/api/v0/boxes/1/webhook'  }).not_to be_routable }
    specify { expect({    get: '/api/v0/boxes/1/terminal' }).not_to be_routable }
    specify { expect({    get: '/api/v0/boxes/1/default_public_key' }).not_to be_routable }
    specify { expect({   post: '/api/v0/boxes/1/add_public_key_to_github' }).not_to be_routable }
  end
end
