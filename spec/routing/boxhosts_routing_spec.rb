require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { expect(get: '/boxhosts').to route_to controller: 'boxhosts', action: 'index'  }
  end
end
