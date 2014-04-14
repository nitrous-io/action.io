require 'spec_helper'

describe Admin::RefundsController do
  describe 'routing' do
    specify { expect(get: '/admin/refunds').to route_to controller: 'admin/refunds', action: 'index' }
    specify { expect(get: '/admin/refunds/new').to route_to controller: 'admin/refunds', action: 'new' }
    specify { expect(post: '/admin/refunds').to route_to controller: 'admin/refunds', action: 'create' }
    specify { expect(get: '/admin/refunds/find_charges').to route_to controller: 'admin/refunds', action: 'find_charges' }
  end
end
