require 'spec_helper'

describe Admin::InvitesController do
  describe 'routing' do
    specify { { post: '/admin/invites/1/send_invite' }.should route_to controller: 'admin/invites', action: 'send_invite', id: '1' }
  end
end
