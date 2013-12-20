require 'spec_helper'

describe Api::V0::BoxTemplatesController do
  describe 'routing' do
    specify { expect({    get: '/api/v0/box_templates'   }).to route_to controller: 'api/v0/box_templates', action: 'index', format: 'json' }
  end
end
