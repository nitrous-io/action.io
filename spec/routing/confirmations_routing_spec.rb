require 'spec_helper'

describe ConfirmationsController do
  describe 'routing' do
    specify { expect({ get: '/confirmations/new' }).to route_to controller: 'confirmations', action: 'new' }
    specify { expect({ post: '/confirmations' }).to route_to controller: 'confirmations', action: 'create' }
    specify { expect({ delete: '/confirmations' }).to route_to controller: 'confirmations', action: 'destroy' }
  end
end
