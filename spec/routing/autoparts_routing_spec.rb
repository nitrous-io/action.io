require 'spec_helper'

describe AutopartsController do
  specify { expect(post:   '/autoparts/webhook').to route_to controller: 'autoparts', action: 'webhook', format: "json" }
end
