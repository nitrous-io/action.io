require 'spec_helper'

describe Users::RegistrationsController do
  describe 'routing' do
    specify { { get:    '/users/sign_up'  }.should route_to controller: 'users/registrations', action: 'new' }
    specify { { post:   '/users'          }.should route_to controller: 'users/registrations', action: 'create' }
    specify { { get:    '/users/cancel'   }.should route_to controller: 'users/registrations', action: 'cancel' }
    specify { { get:    '/users/edit'     }.should route_to controller: 'users/registrations', action: 'edit' }
    specify { { put:    '/users'          }.should route_to controller: 'users/registrations', action: 'update' }
    specify { { delete: '/users'          }.should route_to controller: 'users/registrations', action: 'destroy' }
    specify { { get: '/users/confirmation_required' }.should route_to controller: 'users/registrations', action: 'confirmation_required' }
  end
end

