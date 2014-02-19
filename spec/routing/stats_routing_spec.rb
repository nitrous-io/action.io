require 'spec_helper'

describe StatsController do
  describe 'routing' do
    specify { expect({ get: '/stats/boxes_count_by_group' }).to route_to controller: 'stats', action: 'boxes_count_by_group', format: 'json' }
    specify { expect({ get: '/stats/boxes_count' }).to route_to controller: 'stats', action: 'boxes_count', format: 'json' }
    specify { expect({ get: '/stats/users_count' }).to route_to controller: 'stats', action: 'users_count', format: 'json' }
  end
end
