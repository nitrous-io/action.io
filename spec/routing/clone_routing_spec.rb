require 'spec_helper'

describe CloneController do
  specify { expect(get: '/clone').to route_to controller: 'clone', action: 'index' }
  specify { expect(get: '/clone/embed').to route_to controller: 'clone', action: 'embed' }
end
