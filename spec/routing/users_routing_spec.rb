require 'spec_helper'

describe UsersController do
  describe 'routing' do
    specify { expect({ get: '/user/company' }).to route_to controller: 'users', action: 'company', format: 'json' }
    specify { expect({ put: '/user/intro_seen' }).to route_to controller: 'users', action: 'intro_seen', format: 'json' }
    specify { expect({ put: '/user/chrome_app_installed'}).to route_to controller: 'users', action: 'chrome_app_installed', format: 'json' }
  end
end
