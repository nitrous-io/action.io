require 'spec_helper'

describe Users::ConfirmationsController do
  describe 'routing' do
    specify { { get:    '/users/confirmation/new'   }.should route_to controller: 'users/confirmations', action: 'new' }
    specify { { post:   '/users/confirmation'       }.should route_to controller: 'users/confirmations', action: 'create' }
    specify { { get:    '/users/confirmation'       }.should route_to controller: 'users/confirmations', action: 'show' }
  end
end
