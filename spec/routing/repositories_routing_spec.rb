require 'spec_helper'

describe RepositoriesController do
  specify { expect(get: '/repositories').to route_to controller: 'repositories', action: 'index' }
end
