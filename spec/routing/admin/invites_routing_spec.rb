require 'spec_helper'

describe Admin::InvitesController do
  describe 'routing' do
    specify { expect(get: '/admin/invites').to route_to controller: 'admin/invites', action: 'index' }
    specify { expect(post: '/admin/invites/1/send_invite').to route_to controller: 'admin/invites', action: 'send_invite', id: '1' }
  end
end
