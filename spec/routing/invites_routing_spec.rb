require 'spec_helper'

describe InvitesController do
  describe 'routing' do
    specify { expect({ post: '/invites' }).to route_to controller: 'invites', action: 'create' }
    specify { expect({ get: '/invites' }).to route_to controller: 'invites', action: 'index' }
  end
end
