require 'spec_helper'

describe Api::V0::AuthTokenController do
  specify { expect(get: '/api/v0/auth_token/rainbow').to route_to controller: 'api/v0/auth_token', action: 'issue', format: 'json', name: 'rainbow' }
end
