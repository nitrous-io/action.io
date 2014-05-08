require 'spec_helper'

describe ReceiptsController do
  describe 'routing' do
    specify { expect({ get: '/receipts' }).to route_to controller: 'receipts', action: 'index' }
    specify { expect({ get: '/receipts/1' }).to route_to controller: 'receipts', action: 'show', id: '1' }
  end
end
