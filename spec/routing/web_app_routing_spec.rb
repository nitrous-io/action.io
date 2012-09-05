require 'spec_helper'

describe WebAppController do
  describe 'routing' do
    specify { { get: '/app' }.should route_to controller: 'web_app', action: 'index' }
  end
end

