require 'spec_helper'

describe SnapshotsController do
  describe 'routing' do
    specify { {    get: '/snapshots'   }.should route_to controller: 'snapshots', action: 'index'  }
    specify { {   post: '/snapshots'   }.should route_to controller: 'snapshots', action: 'create' }
    specify { { delete: '/snapshots/1' }.should route_to controller: 'snapshots', action: 'destroy', id: '1' }
  end
end
