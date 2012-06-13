require 'spec_helper'

describe InvitesController do
  describe 'routing' do
    specify { { post: '/invites/request_invite' }.should route_to controller: 'invites', action: 'request_invite' }
  end
end
