require 'spec_helper'

describe InvitesController do
  describe 'routing' do
    specify { { post: '/invites/request_invite' }.should route_to controller: 'invites', action: 'request_invite' }
    specify { { post: '/invites/1/send_invite' }.should route_to controller: 'invites', action: 'send_invite', id: '1' }
  end
end
