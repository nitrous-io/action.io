require 'spec_helper'

describe ProvidersController do
  describe 'routing' do
    specify { { get:  '/providers/show_terms' }.should route_to controller: 'providers', action: 'show_terms' }
    specify { { post: '/providers/agree_terms' }.should route_to controller: 'providers', action: 'agree_terms' }
    specify { { get:  '/providers' }.should route_to controller: 'providers', action: 'index' }
  end
end

