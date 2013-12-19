require 'spec_helper'

describe Boxes::InvitesController do
  describe 'routing' do
    specify {expect({get: '/boxes/1/invites'}).to route_to(controller: "boxes/invites", action: "index", box_id: "1") }
  end
end
