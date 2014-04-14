require 'spec_helper'

describe AdminController do
  describe 'routing' do
    specify { expect(get: '/admin').to route_to controller: 'admin', action: 'index' }
  end
end
