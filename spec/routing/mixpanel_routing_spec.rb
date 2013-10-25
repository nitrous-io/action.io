require 'spec_helper'

describe MixpanelController do
  specify { expect(post: '/mixpanel/confirmation/1day').to route_to controller: 'mixpanel', action: 'confirmation', event: '1day', format: 'json' }
end
