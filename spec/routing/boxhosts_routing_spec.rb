require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { expect(get: '/boxhosts').to route_to controller: 'boxhosts', action: 'index' }
    specify { expect(get: '/boxhosts/123').to route_to controller: 'boxhosts', action: 'show', id: '123' }
    specify { expect(put: '/boxhosts/123').to route_to controller: 'boxhosts', action: 'update', id: '123' }

    specify { expect(put: '/boxhosts/123/provision').to route_to controller: 'boxhosts', action: 'provision', id: '123' }
  end
end
