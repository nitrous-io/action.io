require 'spec_helper'

describe Admin::InvitesController do
  describe 'routing' do
    specify { { post: '/invites/request_invite' }.should route_to controller: 'invites', action: 'request_invite' }
    specify { { post: '/invites' }.should route_to controller: 'invites', action: 'create' }
  end
end
