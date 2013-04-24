require 'spec_helper'

describe Invite do
  it { should     allow_mass_assignment_of :email }
  it { should_not allow_mass_assignment_of :invite_code }
  it { should_not allow_mass_assignment_of :inviting_user_id }

  describe "Validations" do
    subject { create :invite }
    it { should validate_presence_of :email }
    it { should validate_uniqueness_of(:email).scoped_to(:inviting_user_id) }
    it { should_not allow_value("pete@nitrous.io, aj@nitrous.io, arun@nitrous.io").for(:email) }
    it { should_not allow_value(" pete@nitrous.io aj@nitrous.io ").for(:email) }
    it { should_not allow_value("a run@nitrous.io").for(:email) }

    it "should clean up the email string before entry" do
      @invite = create :invite, email: "  spaced@email.com  "
      @invite.email.should == "spaced@email.com"

      @invite = build :invite, email: "i+x@mclov.in"
      @invite.should be_valid

      @invite = create :invite, email: "I@MCloV.IN"
      @invite.email.should == "i@mclov.in"
    end
  end

  describe "Callbacks" do
    it "should set the referral code when created" do
      SecureRandom.should_receive(:urlsafe_base64).and_return("random_referral_code")
      @invite = create :invite, email: "i@mclov.in"
      @invite.referral_code.should == 'random_referral_code'
    end
  end

  describe "Associations" do
    it { should belong_to :inviting_user }
  end

  describe "Scopes" do
    before do
      @invite_1 = create :invite
      @invite_2 = create :invite
      @invite_3 = create :invite, invite_code: 'abcdef'
      @invite_4 = create :invite, invite_code: 'abcdef'
      @invite_5 = create :invite, invite_code: 'abcdef', state: 'accepted'
      @invite_6 = create :invite, invite_code: 'abcdef', state: 'accepted'
      @invite_7 = create :invite, invite_code: 'abcdef'
      @invite_8 = create :invite, invite_code: 'abcdef'

      Timecop.travel(30.days.ago) { @invite_8.activate! }
      Timecop.travel(25.days.ago) { @invite_7.activate! }
      Timecop.travel(15.days.ago) { @invite_3.activate! }
      Timecop.travel(5.days.ago)  { @invite_4.activate! }
      # A reminder was sent to one of the activated invites
      Timecop.travel(13.days.ago) do
        @invite_8.update_attribute :last_reminded_at, Time.now
      end
    end

    context "pending" do
      it "should return invites without an invite code" do
        Invite.pending.to_a.should =~ [@invite_1, @invite_2]
      end
    end

    context "sent" do
      it "should return invites with an invite code" do
        Invite.activated.to_a.should =~ [@invite_3, @invite_4, @invite_7, @invite_8]
      end
    end

    context "accepted" do
      it "should return invites which are accepted" do
        Invite.accepted.to_a.should =~ [@invite_5, @invite_6]
      end
    end

    context "needs_reminder" do
      it "should return invites which are in an activated state and have been created more than two weeks ago" do
        Invite.needs_reminder.to_a.should =~ [@invite_3, @invite_7]
      end
    end
  end

  describe "state machine" do
    describe "#activate" do
      let!(:invite) { create :invite, :email => 'i@mclov.in' }

      before do
        Timecop.freeze
        @now = Time.now
      end

      after do
        Timecop.return
      end

      it "should generate an invite code" do
        invite.activate!
        invite.reload.invite_code.should be_present
      end

      it "should update the activated_at field with the current time" do
        invite.activate!
        invite.reload.activated_at.to_i.should == @now.to_i
      end

      it "decreases the available invites for inviting user" do
        user = create :user, available_invites: 10
        invite = create :invite, email: "i@mclov.in", inviting_user: user
        expect {
          invite.activate!
        }.to change { user.reload.available_invites }.by(-1)
      end
    end

    describe "#accept" do
      let!(:invite) { create :invite, email: 'i@mclov.in', state: 'activated' }

      before do
        Timecop.freeze
        @now = Time.now
      end

      after do
        Timecop.return
      end

      it "should update the activated_at field with the current time" do
        invite.accept!
        invite.reload.accepted_at.to_i.should == @now.to_i
      end
    end
  end

  describe "#generate_invite_code!" do
    before do
      # Once for the referral code (when the Invite model is being created)...
      SecureRandom.should_receive(:urlsafe_base64).ordered.and_return("random_referral_code")
      # and once for the invite code when generate_invite_code! is being called
      SecureRandom.should_receive(:urlsafe_base64).ordered.and_return("random_invite_code")

      @invite = create :invite, :email => 'i@mclov.in'
    end

    it "should use the SHA of the email of the invite for the invite_code and save it" do
      @invite.generate_invite_code!
      @invite.reload.invite_code.should == 'random_invite_code'
    end
  end

  describe "#needs_reminder?" do
    let!(:invite) { create :invite, :email => 'i@mclov.in' }

    context "invite was activated more than 2 weeks ago" do
      before { invite.update_attribute('activated_at', 3.weeks.ago) }

      context "no previous reminder sent" do
        before { invite.update_attribute('last_reminded_at', nil) }

        it "returns true" do
          expect(invite.needs_reminder?).to be_true
        end
      end

      context "previous reminder sent more than two weeks ago" do
        before { invite.update_attribute('last_reminded_at', 3.weeks.ago) }

        it "returns true" do
          expect(invite.needs_reminder?).to be_true
        end
      end

      context "previous reminder sent within the last 2 weeks" do
        before { invite.update_attribute('last_reminded_at', 1.week.ago) }

        it "returns false" do
          expect(invite.needs_reminder?).to be_false
        end
      end
    end

    context "invite was activated within the last 2 weeks" do
      before { invite.update_attribute('activated_at', 1.week.ago) }

      it "returns false" do
        expect(invite.needs_reminder?).to be_false
      end
    end
  end

  describe "#send_reminder!" do
    let(:notifier) { double 'notifier', deliver: true  }

    before do
      @invite = create :invite, :email => 'i@mclov.in'
    end

    it "should set the last reminded timesteamp" do
      Timecop.freeze {
        @invite.send_reminder!
        @invite.reload.last_reminded_at.to_i.should == Time.now.to_i
      }
    end

    it "should deliver the reminder notification" do
      Notifier.should_receive(:invite_reminder).with(@invite).and_return(notifier)
      @invite.send_reminder!
    end
  end
end
