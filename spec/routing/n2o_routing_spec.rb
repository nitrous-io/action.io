require 'spec_helper'

describe N2oController do
  describe 'routing' do
    specify { { get: '/n2o' }.should route_to controller: 'n2o', action: 'index', format: 'json' }
  end
end
