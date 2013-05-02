require 'spec_helper'

describe Admin::InvitesController do
  describe 'routing' do
    specify { { post: '/invites' }.should route_to controller: 'invites', action: 'create' }
    specify { { get: '/invites' }.should route_to controller: 'invites', action: 'index' }
  end
end
