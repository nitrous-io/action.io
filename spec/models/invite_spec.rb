require 'spec_helper'

describe Invite do
  it { should     allow_mass_assignment_of :email }
  it { should_not allow_mass_assignment_of :invite_code }
  it { should_not allow_mass_assignment_of :inviting_user_id }

  describe "Validations" do
    subject { FactoryGirl.create(:invite) }
    it { should validate_presence_of :email }
    it { should validate_uniqueness_of(:email).scoped_to(:inviting_user_id) }
    it { should_not allow_value("pete@action.io, aj@action.io, arun@action.io").for(:email) }
    it { should_not allow_value(" pete@action.io aj@action.io ").for(:email) }
    it { should_not allow_value("a run@action.io").for(:email) }

    it "should strip email string before entry" do
      @invite = FactoryGirl.create(:invite, email: "  spaced@email.com  ")
      @invite.email.should == "spaced@email.com"

      @invite = FactoryGirl.build(:invite, email: "i+x@mclov.in")
      @invite.should be_valid
    end
  end

  describe "Callbacks" do
    it "should set the referral code when created" do
      SecureRandom.should_receive(:urlsafe_base64).and_return("random_referral_code")
      @invite = FactoryGirl.create(:invite, email: "i@mclov.in")
      @invite.referral_code.should == 'random_referral_code'
    end

    it "decreases the available invite of inviting user when created" do
      user = create :user, available_invite: 10
      expect {
        invite = build :invite, email: "i@mclov.in"
        invite.inviting_user = user
        invite.save
      }.to change { user.reload.available_invite }.by(-1)
    end
  end

  describe "Associations" do
    it { should belong_to :inviting_user }
  end

  describe "Scopes" do
    before do
      @invite_1 = FactoryGirl.create(:invite)
      @invite_2 = FactoryGirl.create(:invite)
      @invite_3 = FactoryGirl.create(:invite, :invite_code => 'abcdef', :state => 'activated')
      @invite_4 = FactoryGirl.create(:invite, :invite_code => 'abcdef', :state => 'activated')
      @invite_5 = FactoryGirl.create(:invite, :invite_code => 'abcdef', :state => 'accepted')
      @invite_6 = FactoryGirl.create(:invite, :invite_code => 'abcdef', :state => 'accepted')
    end

    context "pending" do
      it "should return invites without an invite code" do
        Invite.pending.to_a.should =~ [@invite_1, @invite_2]
      end
    end

    context "sent" do
      it "should return invites with an invite code" do
        Invite.activated.to_a.should =~ [@invite_3, @invite_4]
      end
    end

    context "accepted" do
      it "should return invites which are accepted" do
        Invite.accepted.to_a.should =~ [@invite_5, @invite_6]
      end
    end
  end

  describe "state machine" do
    describe "#activate" do
      let!(:invite) { FactoryGirl.create(:invite, :email => 'i@mclov.in') }

      it "should generate an invite code" do
        invite.activate!
        invite.reload.invite_code.should be_present
      end
    end
  end

  describe "#generate_invite_code!" do
    before do
      # Once for the referral code (when the Invite model is being created)...
      SecureRandom.should_receive(:urlsafe_base64).ordered.and_return("random_referral_code")
      # and once for the invite code when generate_invite_code! is being called
      SecureRandom.should_receive(:urlsafe_base64).ordered.and_return("random_invite_code")

      @invite = FactoryGirl.create(:invite, :email => 'i@mclov.in')
    end

    it "should use the SHA of the email of the invite for the invite_code and save it" do
      @invite.generate_invite_code!
      @invite.reload.invite_code.should == 'random_invite_code'
    end
  end

  describe ".for_email" do
    it 'finds invite that has the specified email' do
      invite = create :invite, email: 'i@mclov.in'
      Invite.for_email('i@mclov.in').should eq(invite)
      Invite.for_email('test@non-existing.email').should be_nil
    end
  end
end
