require 'spec_helper'

describe Users::PasswordsController do
  describe 'routing' do
    specify { expect({ get:    '/users/password/new'   }).to route_to controller: 'users/passwords', action: 'new' }
    specify { expect({ get:    '/users/password/edit'  }).to route_to controller: 'users/passwords', action: 'edit' }
    specify { expect({ put:    '/users/password'       }).to route_to controller: 'users/passwords', action: 'update' }
  end
end
