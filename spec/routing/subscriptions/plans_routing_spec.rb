require 'spec_helper'

describe Subscriptions::PlansController do
  describe 'routing' do
    specify { { get: '/subscription/plans' }.should route_to controller: 'subscriptions/plans', action: 'index' }
  end
end
