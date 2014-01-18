require 'spec_helper'

describe Admin::BoxesController do
  describe 'routing' do
    specify { expect({ get: '/admin/boxes' }).to route_to controller: 'admin/boxes', action: 'index' }
    specify { expect({ put: '/admin/boxes/1/retry_start' }).to route_to controller: 'admin/boxes', action: 'retry_start', id: '1' }
    specify { expect({ put: '/admin/boxes/1/retry_stop' }).to route_to controller: 'admin/boxes', action: 'retry_stop', id: '1' }
    specify { expect({ put: '/admin/boxes/1/retry_restart' }).to route_to controller: 'admin/boxes', action: 'retry_restart', id: '1' }
    specify { expect({ put: '/admin/boxes/1/force_terminate' }).to route_to controller: 'admin/boxes', action: 'force_terminate', id: '1' }
  end
end
