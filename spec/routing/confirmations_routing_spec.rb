require 'spec_helper'

describe ConfirmationsController do
  describe 'routing' do
    specify { { get: '/confirmations/new' }.should route_to controller: 'confirmations', action: 'new' }
    specify { { post: '/confirmations' }.should route_to controller: 'confirmations', action: 'create' }
    specify { { delete: '/confirmations' }.should route_to controller: 'confirmations', action: 'destroy' }
  end
end
