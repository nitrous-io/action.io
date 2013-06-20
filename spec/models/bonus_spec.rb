require 'spec_helper'

describe Bonus do
  it { should belong_to :user }

  describe '.bonus_info' do
    before do
      KeyValue.create(key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10)
      KeyValue.create(key: N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS, value: 1)
      KeyValue.create(key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5)
    end

    it 'returns a hash containing information about bonuses' do
      expect(Bonus.bonus_info).to eq({
        invite_friends: 10,
        invite_friends_extra: 1,
        github: 5,
        google: 5,
        twitter: 5,
        facebook: 5,
        linkedin: 5
      })
    end
  end
end
