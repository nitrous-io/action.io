require 'spec_helper'

describe PusherController do
  describe 'routing' do
    specify { { post: '/pusher/auth' }.should route_to controller: 'pusher', action: 'auth' }
  end
end
