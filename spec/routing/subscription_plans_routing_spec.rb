require 'spec_helper'

describe SubscriptionPlansController do
  describe 'routing' do
    specify { { get: '/subscription_plans' }.should route_to controller: 'subscription_plans', action: 'index' }
  end
end

