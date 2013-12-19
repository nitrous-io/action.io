require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { expect({ get: '/box_templates' }).to route_to controller: 'box_templates', action: 'index' }
    specify { expect({ get: '/box_templates/1' }).to route_to controller: 'box_templates', action: 'show', id: '1' }
  end
end
