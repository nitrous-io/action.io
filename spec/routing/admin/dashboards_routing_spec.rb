require 'spec_helper'

describe Admin::DashboardsController do
  describe 'routing' do
    specify { expect({ get: '/admin/dashboards' }).to route_to controller: 'admin/dashboards', action: 'index' }
    specify { expect({ get: '/admin/dashboards/mrr' }).to route_to controller: 'admin/dashboards', action: 'mrr' }
    specify { expect({ get: '/admin/dashboards/mrr.csv' }).to route_to controller: 'admin/dashboards', action: 'mrr', format: 'csv' }
    specify { expect({ get: '/admin/dashboards/cashflow' }).to route_to controller: 'admin/dashboards', action: 'cashflow' }
    specify { expect({ get: '/admin/dashboards/plans' }).to route_to controller: 'admin/dashboards', action: 'plans' }
    specify { expect({ get: '/admin/dashboards/churned_in_period' }).to route_to controller: 'admin/dashboards', action: 'churned_in_period' }
  end
end
