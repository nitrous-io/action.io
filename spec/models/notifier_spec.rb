require 'spec_helper'

describe Notifier do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe ".send_invite" do
    let(:invite) { create :invite, email: 'i@mclov.in', referral_code: 'random_referral_code' }
    before { invite.activate! }

    it 'sends accepted invitation email to user' do
      email = Notifier.send_invite invite.id
      email.should deliver_to("i@mclov.in")
      email.should have_subject("Welcome to Action.IO")
      email.should have_body_text(invite.invite_code)
    end

    it 'includes inviting user when the invite is from an user' do
      user = create :user
      invite.inviting_user = user
      invite.save
      email = Notifier.send_invite invite.id
      email.should have_body_text(user.username)
    end
  end

  describe ".invite_confirmation" do
    let!(:invite) { create :invite, email: 'i@mclov.in', referral_code: 'random_referral_code' }

    before do
      @email = Notifier.invite_confirmation(invite.id)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("i@mclov.in")
    end
  end

  describe ".box_provisioning_failed" do
    let!(:box) { create :box }

    before do
      @email = Notifier.box_provisioning_failed(box.id)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("eng@action.io")
    end
  end
end
