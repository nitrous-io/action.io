require 'spec_helper'

describe BoxesController do
  describe 'routing' do
    specify { { get: '/box_templates' }.should route_to controller: 'box_templates', action: 'index' }
    specify { { get: '/box_templates/1' }.should route_to controller: 'box_templates', action: 'show', id: '1' }
  end
end
