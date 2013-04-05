require 'spec_helper'

describe RainbowController do
  specify { expect(get: '/rainbow/auth_token').to route_to controller: 'rainbow', action: 'auth_token', format: "json" }
end
