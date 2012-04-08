require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { { get:    '/boxes'   }.should route_to controller: 'boxes', action: 'index'  }
    specify { { post:   '/boxes'   }.should route_to controller: 'boxes', action: 'create' }
    specify { { get:    '/boxes/1' }.should route_to controller: 'boxes', action: 'show',    id: '1' }
    specify { { put:    '/boxes/1' }.should route_to controller: 'boxes', action: 'update',  id: '1' }
    specify { { delete: '/boxes/1' }.should route_to controller: 'boxes', action: 'destroy', id: '1' }
  end
end
