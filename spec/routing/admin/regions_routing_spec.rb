require 'spec_helper'

describe Admin::RegionsController do
  describe 'routing' do
    specify { { get: '/admin/regions' }.should route_to controller: 'admin/regions', action: 'index' }
    specify { { put: '/admin/regions/1/start_to_go_down' }.should route_to controller: 'admin/regions', action: 'start_to_go_down', id: '1' }
    specify { { put: '/admin/regions/1/go_down' }.should route_to controller: 'admin/regions', action: 'go_down', id: '1' }
    specify { { put: '/admin/regions/1/go_up' }.should route_to controller: 'admin/regions', action: 'go_up', id: '1' }
    specify { { put: '/admin/regions/1/disable_box_creation' }.should route_to controller: 'admin/regions', action: 'disable_box_creation', id: '1' }
    specify { { put: '/admin/regions/1/enable_box_creation' }.should route_to controller: 'admin/regions', action: 'enable_box_creation', id: '1' }
  end
end
