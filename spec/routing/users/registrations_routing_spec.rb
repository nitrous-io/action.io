require 'spec_helper'

describe Users::RegistrationsController do
  describe 'routing' do
    specify { expect({ get:    '/users/sign_up'  }).to route_to controller: 'users/registrations', action: 'new' }
    specify { expect({ post:   '/users'          }).to route_to controller: 'users/registrations', action: 'create' }
    specify { expect({ get:    '/users/cancel'   }).to route_to controller: 'users/registrations', action: 'cancel' }
    specify { expect({ get:    '/users/edit'     }).to route_to controller: 'users/registrations', action: 'edit' }
    specify { expect({ put:    '/users'          }).to route_to controller: 'users/registrations', action: 'update' }
    specify { expect({ delete: '/users'          }).to route_to controller: 'users/registrations', action: 'destroy' }
    specify { expect({ get: '/users/confirmation_required' }).to route_to controller: 'users/registrations', action: 'confirmation_required' }
  end
end

