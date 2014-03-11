require 'spec_helper'

describe TimingMetricsController do
  describe 'routing' do
    specify { expect({ post: '/timing/sftp_connection' }).to route_to controller: 'timing_metrics', action: 'sftp_connection', format: 'json' }
  end
end
