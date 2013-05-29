require 'spec_helper'

describe WebAppController do
  describe 'routing' do
    specify { { get: '/app' }.should route_to controller: 'web_app', action: 'index' }
    specify { { post: '/app/hide_ide_tour' }.should route_to controller: 'web_app', action: 'hide_ide_tour' }
    specify { { post: '/app/hide_boxes_tour' }.should route_to controller: 'web_app', action: 'hide_boxes_tour' }
  end
end

