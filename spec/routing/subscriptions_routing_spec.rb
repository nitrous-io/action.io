require 'spec_helper'

describe SubscriptionsController do
  describe 'routing' do
    specify { { post: '/subscription' }.should route_to controller: 'subscriptions', action: 'create' }
    specify { { put: '/subscription' }.should route_to controller: 'subscriptions', action: 'update' }
    specify { { delete: '/subscription' }.should route_to controller: 'subscriptions', action: 'destroy' }
    specify { { put: '/subscription/change_card' }.should route_to controller: 'subscriptions', action: 'change_card' }
  end
end
