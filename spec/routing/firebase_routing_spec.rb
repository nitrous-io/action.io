require 'spec_helper'

describe FirebaseController do
  specify { expect(get: '/firebase/auth_token').to route_to controller: 'firebase', action: 'auth_token', format: "json" }
end
