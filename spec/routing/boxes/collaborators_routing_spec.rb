require 'spec_helper'

describe Boxes::CollaboratorsController do
  describe 'routing' do
    specify { expect(get:    '/boxes/1/collaborators').to route_to controller: 'boxes/collaborators', action: 'index',   box_id: '1' }
    specify { expect(put:    '/boxes/1/collaborators/pete').to route_to controller: 'boxes/collaborators', action: 'add',     box_id: '1', username: 'pete' }
    specify { expect(delete: '/boxes/1/collaborators/arun').to route_to controller: 'boxes/collaborators', action: 'remove',  box_id: '1', username: 'arun' }
  end
end
