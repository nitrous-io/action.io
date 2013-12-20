describe Oauth::ApplicationsController do
  describe 'routing' do
    specify { expect({    get: '/oauth/applications'        }).to route_to controller: 'oauth/applications', action: 'index'  }
    specify { expect({   post: '/oauth/applications'        }).to route_to controller: 'oauth/applications', action: 'create' }
    specify { expect({    get: '/oauth/applications/new'    }).to route_to controller: 'oauth/applications', action: 'new'    }
    specify { expect({    get: '/oauth/applications/1/edit' }).to route_to controller: 'oauth/applications', action: 'edit',    id: '1' }
    specify { expect({    put: '/oauth/applications/1'      }).to route_to controller: 'oauth/applications', action: 'update',  id: '1' }
    specify { expect({    get: '/oauth/applications/1'      }).to route_to controller: 'oauth/applications', action: 'show',    id: '1' }
    specify { expect({ delete: '/oauth/applications/1'      }).to route_to controller: 'oauth/applications', action: 'destroy', id: '1' }
  end
end
