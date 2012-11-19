require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { { get:    '/boxes'   }.should route_to controller: 'boxes', action: 'index'  }
    specify { { post:   '/boxes'   }.should route_to controller: 'boxes', action: 'create' }
    specify { { get:    '/boxes/1' }.should route_to controller: 'boxes', action: 'show',    id: '1' }
    specify { { put:    '/boxes/1' }.should route_to controller: 'boxes', action: 'update',  id: '1' }
    specify { { delete: '/boxes/1' }.should route_to controller: 'boxes', action: 'destroy', id: '1' }

    specify { { put: '/boxes/1/start'   }.should route_to controller: 'boxes', action: 'start',    id: '1' }
    specify { { put: '/boxes/1/stop'    }.should route_to controller: 'boxes', action: 'stop',     id: '1' }
    specify { { put: '/boxes/1/webhook' }.should route_to controller: 'boxes', action: 'webhook',  id: '1' }


    specify { { post: '/boxes/1/add_public_key_to_github' }.should route_to controller: 'boxes', action: 'add_public_key_to_github', id: '1' }
    specify { { get: '/boxes/1/terminal' }.should route_to controller: 'boxes', action: 'terminal', id: '1' }
    specify { { get: '/boxes/1/default_public_key' }.should route_to controller: 'boxes', action: 'default_public_key', id: '1' }
  end
end
