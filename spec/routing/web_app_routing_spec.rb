require 'spec_helper'

describe WebAppController do
  describe 'routing' do
    specify { { get: '/app' }.should route_to controller: 'web_app', action: 'index' }
    specify { { post: '/app/end_intro' }.should route_to controller: 'web_app', action: 'end_intro' }
  end
end

