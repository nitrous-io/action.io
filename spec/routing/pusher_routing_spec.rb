require 'spec_helper'

describe PusherController do
  describe 'routing' do
    specify { expect({ post: '/pusher/auth' }).to route_to controller: 'pusher', action: 'auth' }
  end
end
