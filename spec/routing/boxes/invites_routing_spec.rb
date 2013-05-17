require 'spec_helper'

describe Boxes::InvitesController do
  describe 'routing' do
    specify {{get: '/boxes/1/invites'}.should route_to(controller: "boxes/invites", action: "index", box_id: "1") }
  end
end
