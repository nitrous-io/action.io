require 'spec_helper'

describe BoxAdminsController do
  describe 'routing' do
    specify { { get: '/boxes/1/admins' }.should route_to controller: 'box_admins', action: 'index', box_id: '1' }
    specify { { post: '/boxes/1/admins' }.should route_to controller: 'box_admins', action: 'create', box_id: '1' }
  end
end
