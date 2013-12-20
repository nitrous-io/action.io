require 'spec_helper'

describe StatsController do
  describe 'routing' do
    specify { expect({ get: '/stats/boxes_count_by_region' }).to route_to controller: 'stats', action: 'boxes_count_by_region', format: 'json' }
    specify { expect({ get: '/stats/boxes_count_by_template' }).to route_to controller: 'stats', action: 'boxes_count_by_template', format: 'json' }
    specify { expect({ get: '/stats/boxes_count_by_memory' }).to route_to controller: 'stats', action: 'boxes_count_by_memory', format: 'json' }
    specify { expect({ get: '/stats/boxes_count_by_storage' }).to route_to controller: 'stats', action: 'boxes_count_by_storage', format: 'json' }
    specify { expect({ get: '/stats/boxes_running_count' }).to route_to controller: 'stats', action: 'boxes_running_count', format: 'json' }
    specify { expect({ get: '/stats/boxes_total_count' }).to route_to controller: 'stats', action: 'boxes_total_count', format: 'json' }
    specify { expect({ get: '/stats/boxes_unterminated_count' }).to route_to controller: 'stats', action: 'boxes_unterminated_count', format: 'json' }
    specify { expect({ get: '/stats/users_total_count' }).to route_to controller: 'stats', action: 'users_total_count', format: 'json' }
  end
end
