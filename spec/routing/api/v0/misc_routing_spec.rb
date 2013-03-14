require 'spec_helper'

describe Api::V0::MiscController do
  describe 'routing' do
    specify { expect(get: '/api/v0/scopes').to route_to controller: 'api/v0/misc', action: 'scopes', format: 'json' }
  end
end
