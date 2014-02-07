require 'spec_helper'

describe SnapshotsController do
  describe 'routing' do
    specify { expect(get: '/snapshots').to route_to controller: 'snapshots', action: 'index'  }
    specify { expect(post: '/snapshots').to route_to controller: 'snapshots', action: 'create' }
    specify { expect(delete: '/snapshots/1').to route_to controller: 'snapshots', action: 'destroy', id: '1' }
  end
end
