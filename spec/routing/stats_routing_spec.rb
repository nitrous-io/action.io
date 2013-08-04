require 'spec_helper'

describe StatsController do
  describe 'routing' do
    specify { { get: '/stats/boxes_count_by_region' }.should route_to controller: 'stats', action: 'boxes_count_by_region', format: 'json' }
    specify { { get: '/stats/boxes_count_by_template' }.should route_to controller: 'stats', action: 'boxes_count_by_template', format: 'json' }
    specify { { get: '/stats/boxes_count_by_memory' }.should route_to controller: 'stats', action: 'boxes_count_by_memory', format: 'json' }
    specify { { get: '/stats/boxes_count_by_storage' }.should route_to controller: 'stats', action: 'boxes_count_by_storage', format: 'json' }
    specify { { get: '/stats/boxes_running_count' }.should route_to controller: 'stats', action: 'boxes_running_count', format: 'json' }
    specify { { get: '/stats/boxes_total_count' }.should route_to controller: 'stats', action: 'boxes_total_count', format: 'json' }
    specify { { get: '/stats/boxes_unterminated_count' }.should route_to controller: 'stats', action: 'boxes_unterminated_count', format: 'json' }
    specify { { get: '/stats/users_total_count' }.should route_to controller: 'stats', action: 'users_total_count', format: 'json' }
  end
end
