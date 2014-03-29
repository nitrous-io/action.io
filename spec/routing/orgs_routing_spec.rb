require 'spec_helper'

describe OrgsController do
  describe 'routing' do
    specify { expect({ post:   '/orgs'   }).to route_to controller: 'orgs', action: 'create' }
  end
end

