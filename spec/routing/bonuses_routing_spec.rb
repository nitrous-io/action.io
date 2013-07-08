require 'spec_helper'

describe BonusesController do
  describe 'routing' do
    specify { { get: '/bonus' }.should route_to controller: 'bonuses', action: 'show', format: 'json' }
    specify { { put: '/bonus/twitter_follow' }.should route_to controller: 'bonuses', action: 'twitter_follow', format: 'json' }
    specify { { put: '/bonus/send_tweet' }.should route_to controller: 'bonuses', action: 'send_tweet', format: 'json' }
  end
end
