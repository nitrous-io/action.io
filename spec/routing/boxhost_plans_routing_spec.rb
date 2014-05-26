require 'spec_helper'

describe BoxhostPlansController do
  describe 'routing' do
    specify { expect({ get: '/boxhost_plans' }).to route_to controller: 'boxhost_plans', action: 'index' }
    specify { expect({ get: '/boxhost_plans/123' }).to route_to controller: 'boxhost_plans', action: 'show', id: '123' }
    specify { expect({ post: '/boxhost_plans/123/subscribe' }).to route_to controller: 'boxhost_plans', action: 'subscribe', id: '123' }
  end
end
