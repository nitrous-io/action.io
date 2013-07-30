require 'spec_helper'

describe BoxLimitHitEvent do
  describe "validations" do
    it { should validate_presence_of :box_id }
    it { should validate_presence_of :kind   }
    it { should validate_presence_of :limit_hit_at }
    it { should validate_presence_of :logged_event_id }

    it { should validate_uniqueness_of :logged_event_id }
  end
end
