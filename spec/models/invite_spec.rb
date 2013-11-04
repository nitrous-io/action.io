require 'spec_helper'

describe Invite do
  it { should     allow_mass_assignment_of :email }
  it { should_not allow_mass_assignment_of :inviting_user_id }
  it { should_not allow_mass_assignment_of :invited_user_id }

  describe "Validations" do
    subject { create :invite }
    it { should validate_presence_of :email }
    it { should validate_presence_of :inviting_user_id }
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

  describe "Associations" do
    it { should belong_to :inviting_user }
    it { should belong_to :invited_user  }
    it { should have_one  :n2o_fill }
  end

  describe "callbacks" do
    let!(:user)     { create :user }
    let!(:invited_user) { create :user }
    let!(:invited_user_2) { create :user }
    let!(:invite_1) { create :invite, referral_code: user.referral_code, inviting_user: user, invited_user: invited_user }
    let!(:invite_2) { create :invite, referral_code: user.referral_code, inviting_user: user, state: 'accepted' }
    # Legacy invite which existed previously
    let!(:invite_3) { create :invite, referral_code: 'abcdef', inviting_user: user, state: 'accepted' }
    let!(:invite_4) { create :invite, referral_code: user.referral_code, inviting_user: user, invited_user: invited_user_2 }

    before do
      create :key_value, key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10
      create :key_value, key: N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS, value: 1
      create :key_value, key: N2oFill::N2O_INVITED_SIGNUP_BONUS, value: 10
      create :key_value, key: Invite::INVITE_MAX_REWARDABLE, value: 2

      SetMixpanelPropertyJob.stub(:submit_job)
    end

    it "should set the accepted_invites on User to be the total number of accepted invites" do
      expect {
        invite_1.accept!
      }.to change(user, :accepted_invites).from(0).to(2)
    end

    it "should track the number of accepted invites in Mixpanel" do
      SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :accepted_invites, 2)
      invite_1.accept!
    end

    it "should set the bonus's invited_friends attribute to the current time" do
      expect(user.bonus.invite_friends).to be_nil
      invite_1.accept!
      expect(user.bonus.reload.invite_friends).to be_present
    end

    it "should set the Mixpanel invited_friends property to be true" do
      SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :invited_friends, true)
      invite_1.accept!
    end

    context "when number of accepted_invites for the user is less than his available invites" do
      before do
        user.update_attribute(:rewardable_invites_count, 5)
      end

      it "should create an N2oFill object for the inviting user" do
        expect {
          invite_1.accept!
        }.to change(user.n2o_fills, :count).from(0).to(1)

        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eq KeyValue[N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS]
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITING_USER_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS
        expect(n2o_fill.resource).to eq invite_1
      end

      it "should create an N2oFill object for the invited user" do
        expect {
          invite_1.accept!
        }.to change(invited_user.n2o_fills, :count).from(0).to(1)

        n2o_fill = invited_user.n2o_fills.last
        expect(n2o_fill.amount).to eq KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITED_USER_SIGNUP_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITED_SIGNUP_BONUS
        expect(n2o_fill.resource).to be_nil
      end
    end

    context "when number of accepted_invites for the user is greater than his available invites and lower than the redeemable cap" do
      before do
        user.update_attribute(:rewardable_invites_count, 0)
      end

      it "should create an N2oFill object for the inviting user" do
        expect {
          invite_1.accept!
        }.to change(user.n2o_fills, :count).from(0).to(1)

        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eq KeyValue[N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS]
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITING_USER_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS
        expect(n2o_fill.resource).to eq invite_1
      end

      it "should create an N2oFill object for the invited user" do
        expect {
          invite_1.accept!
        }.to change(invited_user.n2o_fills, :count).from(0).to(1)

        n2o_fill = invited_user.n2o_fills.last
        expect(n2o_fill.amount).to eq KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITED_USER_SIGNUP_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITED_SIGNUP_BONUS
      end
    end

    context "when number of accepted_invites for the user is greater than his available invites and higher than the redeemable cap" do
      before do
        user.update_attribute(:rewardable_invites_count, 0)
        invite_1.accept!
      end

      it "should create an N2oFill object for the inviting user" do
        expect {
          invite_4.accept!
        }.to_not change(user.n2o_fills, :count)
      end

      it "should create an N2oFill object for the invited user" do
        expect {
          invite_4.accept!
        }.to change(invited_user_2.n2o_fills, :count).from(0).to(1)

        n2o_fill = invited_user_2.n2o_fills.last
        expect(n2o_fill.amount).to eq KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITED_USER_SIGNUP_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITED_SIGNUP_BONUS
      end
    end

    context "when number of accepted_invites for the user is less than his available invites but he has referral_n2o set to a number" do
      before do
        user.update_attribute(:rewardable_invites_count, 5)
        user.update_attribute(:referral_n2o, 50)
      end

      it "should create an N2oFill object for the inviting user" do
        expect {
          invite_1.accept!
        }.to change(user.n2o_fills, :count).from(0).to(1)

        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eq KeyValue[N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS]
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITING_USER_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS
        expect(n2o_fill.resource).to eq invite_1
      end

      it "should create an N2oFill object for the invited user" do
        expect {
          invite_1.accept!
        }.to change(invited_user.n2o_fills, :count).from(0).to(1)

        n2o_fill = invited_user.n2o_fills.last
        expect(n2o_fill.amount).to eq user.referral_n2o
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITED_USER_SIGNUP_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITED_SIGNUP_BONUS
      end
    end

    context "when number of accepted_invites for the user is greater than his available invites and higher than the redeemable cap but inviting user has referral_n2o set" do
      before do
        user.update_attribute(:rewardable_invites_count, 0)
        user.update_attribute(:referral_n2o, 50)

        invite_1.accept!
      end

      it "should create an N2oFill object for the inviting user" do
        expect {
          invite_4.accept!
        }.to_not change(user.n2o_fills, :count)
      end

      it "should create an N2oFill object for the invited user" do
        expect {
          invite_4.accept!
        }.to change(invited_user_2.n2o_fills, :count).from(0).to(1)

        n2o_fill = invited_user_2.n2o_fills.last
        expect(n2o_fill.amount).to eq user.referral_n2o
        expect(n2o_fill.kind).to eq N2oFill::Kind::INVITED_USER_SIGNUP_BONUS
        expect(n2o_fill.description).to eq N2oFill::N2O_INVITED_SIGNUP_BONUS
      end
    end
  end

  describe "Scopes" do
    before do
      @invite_1 = @invite_2 = @invite_3 = @invite_4 = @invite_5 = @invite_6 = nil

      Timecop.travel(30.days.ago) { @invite_1 = create :invite }
      Timecop.travel(25.days.ago) { @invite_2 = create :invite }
      @invite_3 = create :invite, state: 'accepted'
      @invite_4 = create :invite, state: 'accepted'
      Timecop.travel(15.days.ago) { @invite_5 = create :invite }
      Timecop.travel(5.days.ago)  { @invite_6 = create :invite }

      # A reminder was sent to one of the activated invites
      Timecop.travel(13.days.ago) do
        @invite_2.update_attribute :last_reminded_at, Time.now
      end
    end

    context "activated" do
      it "should return invites with an invite code" do
        Invite.activated.to_a.should =~ [@invite_1, @invite_2, @invite_5, @invite_6]
      end
    end

    context "accepted" do
      it "should return invites which are accepted" do
        Invite.accepted.to_a.should =~ [@invite_3, @invite_4]
      end
    end

    context "needs_reminder" do
      it "should return invites which are in an activated state and have been created more than two weeks ago" do
        Invite.needs_reminder.to_a.should =~ [@invite_1, @invite_5]
      end
    end
  end

  describe "state machine" do
    describe "#accept" do
      let!(:invite) { create :invite, email: 'i@mclov.in', state: 'activated' }

      before do
        Timecop.freeze
        @now = Time.now

        invite.invited_user = create(:user)
      end

      after do
        Timecop.return
      end

      it "should update the accepted_at field with the current time" do
        TrackMixpanelEventJob.should_receive(:submit_job).with('Invite Accepted', invite.invited_user_id)

        invite.accept!
        invite.reload.accepted_at.to_i.should == @now.to_i
      end
    end
  end

  describe "#needs_reminder?" do
    let!(:invite) { create :invite, email: 'i@mclov.in' }

    context "invite was activated more than 2 weeks ago" do
      before { invite.update_attribute('created_at', 3.weeks.ago) }

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
      before { invite.update_attribute('created_at', 1.week.ago) }

      it "returns false" do
        expect(invite.needs_reminder?).to be_false
      end
    end
  end

  describe "#n2o_earned" do
    let!(:invite) { create :invite }

    context "when it does not have an n2o_fill associated with it" do
      it "should return nil" do
        expect(invite.n2o_earned).to be_nil
      end
    end

    context "when it does not have an n2o_fill associated with it" do
      let!(:n2o_fill) { create :n2o_fill, resource: invite, amount: 20 }

      it "should return the amount associated with the n2o_fill" do
        expect(invite.n2o_earned).to eql 20
      end
    end
  end
end
