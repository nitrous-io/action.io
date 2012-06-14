require 'spec_helper'

describe Notifier do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  context ".invite_confirmation" do
    let(:user) { create :user, email: 'i@mclov.in' }

    before(:each) do
      @email = Notifier.invite_confirmation(user.id)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("i@mclov.in")
    end
  end

end