require 'spec_helper'

describe Api::V0::BoxesController do
  describe 'routing' do
    specify { { get: '/api/v0/boxes'   }.should route_to controller: 'api/v0/boxes', action: 'index', format: 'json'  }
    specify { { get: '/api/v0/boxes/1' }.should route_to controller: 'api/v0/boxes', action: 'show',  format: 'json', id: '1' }

    specify { { post: '/api/v0/boxes' }.should route_to controller: 'api/v0/boxes', action: 'create',   format: 'json' }

    specify { { put: '/api/v0/boxes/1/start'   }.should route_to controller: 'api/v0/boxes', action: 'start',   format: 'json', id: '1' }
    specify { { put: '/api/v0/boxes/1/stop'    }.should route_to controller: 'api/v0/boxes', action: 'stop',    format: 'json', id: '1' }
    specify { { put: '/api/v0/boxes/1/restart' }.should route_to controller: 'api/v0/boxes', action: 'restart', format: 'json', id: '1' }

    specify { { delete: '/api/v0/boxes/1' }.should_not be_routable }
    specify { {    put: '/api/v0/boxes/1/webhook'  }.should_not be_routable }
    specify { {    get: '/api/v0/boxes/1/terminal' }.should_not be_routable }
    specify { {    get: '/api/v0/boxes/1/default_public_key' }.should_not be_routable }
    specify { {   post: '/api/v0/boxes/1/add_public_key_to_github' }.should_not be_routable }
  end
end
