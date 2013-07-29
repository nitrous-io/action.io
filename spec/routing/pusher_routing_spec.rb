require 'spec_helper'

describe PusherController do
  describe 'routing' do
    specify { { get: '/pusher/auth' }.should route_to controller: 'pusher', action: 'auth' }
  end
end
