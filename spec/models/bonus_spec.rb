require 'spec_helper'

describe Bonus do
  it { should belong_to :user }

  describe '.available_bonuses' do
    before do
      KeyValue.create(key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10)
      KeyValue.create(key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5)
    end

    it 'returns a hash containing information about available bonuses' do
      expect(Bonus.available_bonuses).to eq({
        invite_friends: 10, # 10 points
        github: 5,
        google: 5,
        twitter: 5,
        facebook: 5,
        linkedin: 5
      })
    end
  end
end
