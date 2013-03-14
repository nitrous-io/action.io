require 'spec_helper'

describe VagrantController do
  specify { expect(get: '/vagrant/access_token').to route_to controller: 'vagrant', action: 'access_token' }
end
