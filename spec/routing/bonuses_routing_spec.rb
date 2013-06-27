require 'spec_helper'

describe BonusesController do
  describe 'routing' do
    specify { { get: '/bonus' }.should route_to controller: 'bonuses', action: 'show', format: 'json' }
  end
end
