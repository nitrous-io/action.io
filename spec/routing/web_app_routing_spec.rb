require 'spec_helper'

describe WebAppController do
  describe 'routing' do
    specify { expect({ get: '/app' }).to route_to controller: 'web_app', action: 'index' }
  end
end

