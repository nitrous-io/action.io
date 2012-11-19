describe Oauth::ApplicationsController do
  describe 'routing' do
    specify { {    get: '/oauth/applications'        }.should route_to controller: 'oauth/applications', action: 'index'  }
    specify { {   post: '/oauth/applications'        }.should route_to controller: 'oauth/applications', action: 'create' }
    specify { {    get: '/oauth/applications/new'    }.should route_to controller: 'oauth/applications', action: 'new'    }
    specify { {    get: '/oauth/applications/1/edit' }.should route_to controller: 'oauth/applications', action: 'edit',    id: '1' }
    specify { {    put: '/oauth/applications/1'      }.should route_to controller: 'oauth/applications', action: 'update',  id: '1' }
    specify { {    get: '/oauth/applications/1'      }.should route_to controller: 'oauth/applications', action: 'show',    id: '1' }
    specify { { delete: '/oauth/applications/1'      }.should route_to controller: 'oauth/applications', action: 'destroy', id: '1' }
  end
end
