require 'spec_helper'

describe Users::PasswordsController do
  describe 'routing' do
    specify { { get:    '/users/password/new'   }.should route_to controller: 'users/passwords', action: 'new' }
    specify { { get:    '/users/password/edit'  }.should route_to controller: 'users/passwords', action: 'edit' }
    specify { { put:    '/users/password'       }.should route_to controller: 'users/passwords', action: 'update' }
  end
end
