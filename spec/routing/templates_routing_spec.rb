require 'spec_helper'

describe TemplatesController do
  describe 'routing' do
    specify { { get:    '/templates'   }.should route_to controller: 'templates', action: 'index'  }
    specify { { post:   '/templates'   }.should route_to controller: 'templates', action: 'create' }
    specify { { get:    '/templates/1' }.should route_to controller: 'templates', action: 'show',    id: '1' }
    specify { { put:    '/templates/1' }.should route_to controller: 'templates', action: 'update',  id: '1' }
    specify { { delete: '/templates/1' }.should route_to controller: 'templates', action: 'destroy', id: '1' }
  end
end
