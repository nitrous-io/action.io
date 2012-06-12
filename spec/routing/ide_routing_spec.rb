require 'spec_helper'

describe IdeController do
  describe 'routing' do
    specify { { get: '/ide' }.should route_to controller: 'ide', action: 'index' }
  end
end

