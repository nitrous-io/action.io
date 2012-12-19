require 'spec_helper'

describe DocumentsController do
  describe 'routing' do
    specify { { get: '/boxes/1/documents' }.should route_to controller: 'documents', action: 'index', box_id: '1' }
    specify { { post: '/boxes/1/documents' }.should route_to controller: 'documents', action: 'create', box_id: '1' }
    specify { { delete: '/boxes/1/documents/2' }.should route_to controller: 'documents', action: 'destroy', box_id: '1', id: '2' }
  end
end
