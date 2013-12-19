require 'spec_helper'

describe SubscriptionsController do
  describe 'routing' do
    specify { expect({ post: '/subscription' }).to route_to controller: 'subscriptions', action: 'create' }
    specify { expect({ put: '/subscription' }).to route_to controller: 'subscriptions', action: 'update' }
    specify { expect({ delete: '/subscription' }).to route_to controller: 'subscriptions', action: 'destroy' }
    specify { expect({ put: '/subscription/change_card' }).to route_to controller: 'subscriptions', action: 'change_card' }
  end
end
