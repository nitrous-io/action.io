require 'spec_helper'

describe Notifier do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  context ".invite_confirmation" do
    let!(:invite) { create :invite, email: 'i@mclov.in', referral_code: 'random_referral_code' }

    before do
      @email = Notifier.invite_confirmation(invite.id)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("i@mclov.in")
    end
  end

end