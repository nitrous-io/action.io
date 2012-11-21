require 'spec_helper'

describe Providers::AddonsController do
  describe 'routing' do
    specify { { post: '/providers/addons'     }.should route_to controller: 'providers/addons', action: 'create' }
    specify { { get:  '/providers/addons/1'   }.should route_to controller: 'providers/addons', action: 'show', id: '1' }
    specify { { get:  '/providers/addons/new' }.should route_to controller: 'providers/addons', action: 'new' }
  end
end

