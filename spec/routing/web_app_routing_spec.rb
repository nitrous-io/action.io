require 'spec_helper'

describe WebAppController do
  describe 'routing' do
    specify { { get: '/app' }.should route_to controller: 'web_app', action: 'index' }
    specify { { get: '/app/logged_in' }.should route_to controller: 'web_app', action: 'logged_in' }
  end
end

