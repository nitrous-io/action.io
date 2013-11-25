require 'spec_helper'

describe AuthTokenController do
  specify { expect(get: '/auth_token/rainbow').to route_to controller: 'auth_token', action: 'issue', format: 'json', name: 'rainbow' }
end
