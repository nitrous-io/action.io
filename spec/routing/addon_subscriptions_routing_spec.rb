require 'spec_helper'

describe AddonSubscriptionsController do
  describe 'routing' do
    specify { { get: '/boxes/1/addon_subscriptions' }.should route_to controller: 'addon_subscriptions', action: 'index', box_id: "1", format: 'json' }
    specify { { get: '/addon_subscriptions/1' }.should route_to controller: 'addon_subscriptions', action: 'show', id: "1", format: 'json' }
    specify { { post: '/addon_subscriptions' }.should route_to controller: 'addon_subscriptions', action: 'create', format: 'json' }
    specify { { delete: '/addon_subscriptions/1' }.should route_to controller: 'addon_subscriptions', action: 'destroy', id: "1", format: 'json' }
  end
end
