require 'spec_helper'

describe UsersController do
  describe 'routing' do
    specify { { put: '/user/intro_seen' }.should route_to controller: 'users', action: 'intro_seen', format: 'json' }
    specify { { put: '/user/chrome_app_installed'}.should route_to controller: 'users', action: 'chrome_app_installed', format: 'json' }
  end
end
