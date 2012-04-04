require 'spec_helper'

describe ConsoleController do
  describe 'routing' do
    specify { { get: '/console' }.should route_to controller: 'console', action: 'index' }
  end
end
