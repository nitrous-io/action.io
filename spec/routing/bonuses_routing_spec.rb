require 'spec_helper'

describe BonusesController do
  describe 'routing' do
    specify { expect({ get: '/bonus' }).to route_to controller: 'bonuses', action: 'show', format: 'json' }
    specify { expect({ put: '/bonus/twitter_follow' }).to route_to controller: 'bonuses', action: 'twitter_follow', format: 'json' }
    specify { expect({ put: '/bonus/send_tweet' }).to route_to controller: 'bonuses', action: 'send_tweet', format: 'json' }
    specify { expect({ delete: '/bonus/disconnect/github' }).to route_to controller: 'bonuses', action: 'disconnect', service: 'github', format: 'json' }
  end
end
