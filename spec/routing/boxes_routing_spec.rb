require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { expect({    get: '/boxes'   }).to route_to controller: 'boxes', action: 'index'  }
    specify { expect({   post: '/boxes'   }).to route_to controller: 'boxes', action: 'create' }
    specify { expect({    get: '/boxes/1' }).to route_to controller: 'boxes', action: 'show',    id: '1' }
    specify { expect({    put: '/boxes/1' }).to route_to controller: 'boxes', action: 'update',  id: '1' }
    specify { expect({ delete: '/boxes/1' }).to route_to controller: 'boxes', action: 'destroy', id: '1' }

    specify { expect({ put: '/boxes/1/start'   }).to route_to controller: 'boxes', action: 'start',   id: '1' }
    specify { expect({ put: '/boxes/1/stop'    }).to route_to controller: 'boxes', action: 'stop',    id: '1' }
    specify { expect({ put: '/boxes/1/restart' }).to route_to controller: 'boxes', action: 'restart', id: '1' }
    specify { expect({ put: '/boxes/1/webhook' }).to route_to controller: 'boxes', action: 'webhook', id: '1' }
    specify { expect({ put: '/boxes/1/provision' }).to route_to controller: 'boxes', action: 'provision', id: '1' }

    specify { expect({ post: '/boxes/1/start'   }).to route_to controller: 'boxes', action: 'start',   id: '1' }
    specify { expect({ post: '/boxes/1/stop'    }).to route_to controller: 'boxes', action: 'stop',    id: '1' }
    specify { expect({ post: '/boxes/1/restart' }).to route_to controller: 'boxes', action: 'restart', id: '1' }
    specify { expect({ post: '/boxes/1/webhook' }).to route_to controller: 'boxes', action: 'webhook', id: '1' }
    specify { expect({ post: '/boxes/1/provision' }).to route_to controller: 'boxes', action: 'provision', id: '1' }

    specify { expect({ get: '/boxes/1/terminal' }).to route_to controller: 'boxes', action: 'terminal', id: '1' }

    specify { expect({ get: '/boxes/1/info' }).to route_to controller: 'boxes', action: 'info', id: '1' }

    specify { expect({  get: '/boxes/1/default_public_key' }).to route_to controller: 'boxes', action: 'default_public_key', id: '1' }
    specify { expect({ post: '/boxes/1/add_public_key_to_github' }).to route_to controller: 'boxes', action: 'add_public_key_to_github', id: '1' }

    specify { expect(post: '/boxes/1/touch').to route_to controller: 'boxes', action: 'touch', id: '1' }
    specify { expect(put: '/boxes/1/auth').to route_to controller: 'boxes', action: 'auth', id: '1' }
  end
end
