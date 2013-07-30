require 'spec_helper'

describe PapertrailController do
  specify { expect(post: '/papertrail/webhook').to route_to controller: 'papertrail', action: 'webhook', format: 'json' }
end
