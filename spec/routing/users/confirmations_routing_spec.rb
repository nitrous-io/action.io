require 'spec_helper'

describe Users::ConfirmationsController do
  describe 'routing' do
    specify { expect({ get:    '/users/confirmation/new'   }).to route_to controller: 'users/confirmations', action: 'new' }
    specify { expect({ post:   '/users/confirmation'       }).to route_to controller: 'users/confirmations', action: 'create' }
    specify { expect({ get:    '/users/confirmation'       }).to route_to controller: 'users/confirmations', action: 'show' }
  end
end
