require 'spec_helper'

describe RepositoriesController do
  specify { expect(get: '/clone').to route_to controller: 'repositories', action: 'clone' }
end
