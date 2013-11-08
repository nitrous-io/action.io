require 'spec_helper'

describe Boxes::CollaboratorsController do
  describe 'routing' do
    specify { expect(get: '/boxes/1/collaborators').to route_to controller: 'boxes/collaborators', action: 'index', box_id: '1' }
    specify { expect(post: '/boxes/1/collaborators').to route_to controller: 'boxes/collaborators', action: 'create', box_id: '1' }
    specify { expect(delete: '/boxes/1/collaborators/arun').to route_to controller: 'boxes/collaborators', action: 'remove',  box_id: '1', username: 'arun' }
    specify { expect(post: '/boxes/1/collaborators/arun/notify').to route_to controller: 'boxes/collaborators', action: 'notify',  box_id: '1', username: 'arun' }
  end
end
