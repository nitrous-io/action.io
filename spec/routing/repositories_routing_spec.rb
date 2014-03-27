require 'spec_helper'

describe RepositoriesController do
  specify { expect(get: '/repositories').to route_to controller: 'repositories', action: 'index', format: 'json' }
  specify { expect(get: '/repositories/1').to route_to controller: 'repositories', action: 'show', id: '1', format: 'json' }
  specify { expect(post: '/repositories/identify_scm').to route_to controller: 'repositories', action: 'identify_scm', format: 'json' }
end
