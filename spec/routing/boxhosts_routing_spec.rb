require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { expect(get: '/boxhosts').to route_to controller: 'boxhosts', action: 'index' }
    specify { expect(get: '/boxhosts/123').to route_to controller: 'boxhosts', action: 'show', id: '123' }
  end
end
