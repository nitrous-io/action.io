require 'spec_helper'

describe WebAppController do
  describe 'routing' do
    specify { { get: '/app' }.should route_to controller: 'web_app', action: 'index' }
    specify { { post: '/app/hide_tour' }.should route_to controller: 'web_app', action: 'hide_tour' }
  end
end

