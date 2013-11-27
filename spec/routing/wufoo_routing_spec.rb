require 'spec_helper'

describe WufooController do
  specify { expect(post: '/wufoo/webhook/wat').to route_to controller: 'wufoo', action: 'webhook', form_id: 'wat', format: 'json' }
end
