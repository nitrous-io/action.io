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
      email.should have_subject("Welcome to Nitrous.IO")
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
      @email.should deliver_to("eng@nitrous.io")
    end
  end

  describe ".invite_reminder" do
    let!(:invite) { create :invite, email: 'i@mclov.in', referral_code: 'random_referral_code' }

    before do
      @email = Notifier.invite_reminder(invite)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("i@mclov.in")
      @email.should deliver_from("AJ Solimine <ajs@nitrous.io>")
    end
  end

  describe ".collaboration_invite" do
    let!(:to)   { create :user, email: 'to@mclov.in'                              }
    let!(:from) { create :user, email: 'from@mclov.in', username: 'from_username' }
    let!(:box)  { create :box,  name: 'mclovins-box', owner: from }

    before do
      @email = Notifier.collaboration_invite(from: from.id, to: to.id, box: box.id)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("to@mclov.in")
      @email.should deliver_from("Nitrous.IO Team <hello@nitrous.io>")
      @email.body.should match(/from_username/)
      @email.body.should match(/mclovins-box/)
    end
  end
end
