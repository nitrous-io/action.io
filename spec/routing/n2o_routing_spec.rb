require 'spec_helper'

describe N2oController do
  describe 'routing' do
    specify { expect({ get: '/n2o' }).to route_to controller: 'n2o', action: 'index', format: 'json' }
  end
end
