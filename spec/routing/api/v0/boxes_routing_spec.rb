require 'spec_helper'

describe Api::V0::BoxesController do
  describe 'routing' do
    specify { { get: '/api/v0/boxes'   }.should route_to controller: 'api/v0/boxes', action: 'index'  }
    specify { { get: '/api/v0/boxes/1' }.should route_to controller: 'api/v0/boxes', action: 'show', id: '1' }

    specify { { put: '/api/v0/boxes/1/start'   }.should route_to controller: 'api/v0/boxes', action: 'start',   id: '1' }
    specify { { put: '/api/v0/boxes/1/stop'    }.should route_to controller: 'api/v0/boxes', action: 'stop',    id: '1' }
    specify { { put: '/api/v0/boxes/1/restart' }.should route_to controller: 'api/v0/boxes', action: 'restart', id: '1' }

    specify { {   post: '/api/v0/boxes'   }.should_not be_routable }
    specify { { delete: '/api/v0/boxes/1' }.should_not be_routable }
    specify { {    put: '/api/v0/boxes/1/webhook'  }.should_not be_routable }
    specify { {    get: '/api/v0/boxes/1/terminal' }.should_not be_routable }
    specify { {    get: '/api/v0/boxes/1/default_public_key' }.should_not be_routable }
    specify { {   post: '/api/v0/boxes/1/add_public_key_to_github' }.should_not be_routable }
  end
end
