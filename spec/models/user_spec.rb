require 'spec_helper'

describe User do
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :email }
  it { should allow_mass_assignment_of :full_name }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :password_confirmation }
  it { should allow_mass_assignment_of :remember_me }
  it { should allow_mass_assignment_of :referrer_code }

  it { should_not allow_mass_assignment_of :encrypted_password }
  it { should_not allow_mass_assignment_of :authentication_token }
  it { should_not allow_mass_assignment_of :reset_password_token }
  it { should_not allow_mass_assignment_of :reset_password_sent_at }
  it { should_not allow_mass_assignment_of :remember_created_at }
  it { should_not allow_mass_assignment_of :sign_in_count }
  it { should_not allow_mass_assignment_of :current_sign_in_at }
  it { should_not allow_mass_assignment_of :last_sign_in_at }
  it { should_not allow_mass_assignment_of :current_sign_in_ip }
  it { should_not allow_mass_assignment_of :last_sign_in_ip }
  it { should_not allow_mass_assignment_of :created_at }
  it { should_not allow_mass_assignment_of :updated_at }

  it { should have_many(:authentications).dependent(:destroy) }
  it { should have_many(:box_users).dependent(:destroy) }
  it { should have_many(:boxes).through(:box_users) }
  it { should have_many(:owned_boxes).class_name('Box').dependent(:nullify) }
  it { should have_many(:public_keys).dependent(:destroy) }
  it { should have_many(:oauth_applications).dependent(:destroy) }
  it { should have_many(:owned_invites).class_name('Invite').dependent(:nullify) }
  it { should have_many(:n2o_fills).dependent(:destroy) }
  it { should have_many(:n2o_allocations).dependent(:destroy) }
  it { should have_one(:bonus).dependent(:destroy) }

  describe 'validations' do
    let!(:user) { create :user }

    it { should validate_presence_of :username }
    it { should validate_presence_of :email }

    it { should validate_uniqueness_of :username }
    it { should validate_uniqueness_of :email }

    it { should ensure_length_of(:username).is_at_least(4).is_at_most(20) }
    it { should ensure_length_of(:full_name).is_at_least(0).is_at_most(40) }

    it { should allow_value(nil).for(:full_name) }

    describe '#username' do
      it 'validates uniqueness when the user has authentications' do
        user2 = build :external_authenticated_user
        user2.username = user.username
        user2.should_not be_valid
      end

      it 'allows multiple users with nil username' do
        create :external_authenticated_user
        expect {
          create(:external_authenticated_user).should be_persisted
        }.to_not raise_error(ActiveRecord::RecordInvalid)
      end

      it 'blocks some predefined usernames' do
        user = build :user
        user.should be_valid
        %w(jobs actionio NitrousIO rOoT).each do |name|
          user.username = name
          user.should_not be_valid
        end
      end
    end
  end

  describe "Callbacks" do
    context "before save" do
      it "should set the referral code when created" do
        SecureRandom.should_receive(:urlsafe_base64).and_return("random_referral_code")
        user = create :user
        user.referral_code.should == 'random_referral_code'
      end
    end

    context "after create" do
      context "an invite with the same email address as the user exists" do
        let!(:inviting_user) { create :user }

        before do
          @invite = create :invite, email: 'i@mclov.in', email: 'i@mclov.in', referral_code: inviting_user.referral_code, state: 'activated'
          @new_user = create :user, email: 'i@mclov.in', referrer_code: inviting_user.referral_code
        end

        it "should set invited_user to be the newly created user" do
          expect(@invite.reload.invited_user).to eql @new_user
        end
      end

      context "an invite with a different email address (but same referral code) exists" do
        let!(:inviting_user) { create :user }

        before do
          @invite = create :invite, email: 'i@mclov.in', referral_code: inviting_user.referral_code, state: 'activated'
          @new_user = create :user, email: 'i+1@mclov.in', referrer_code: inviting_user.referral_code

          @new_invite = Invite.where(email: 'i+1@mclov.in', referral_code: inviting_user.referral_code).first
        end

        it "should create a new Invite object" do
          expect(@new_invite).to be_present
        end

        it "should set its inviting_user to be the user who invited" do
          expect(@new_invite.inviting_user).to eql inviting_user
        end

        it "should set invited_user to be the newly created user" do
          expect(@new_invite.invited_user).to eql @new_user
        end
      end

      context "an invite does not exist" do
        let!(:inviting_user) { create :user }

        before do
          @new_user = create :user, email: 'i+1@mclov.in', referrer_code: inviting_user.referral_code
          @new_invite = Invite.where(email: 'i+1@mclov.in', referral_code: inviting_user.referral_code).first
        end

        it "should create a new Invite object" do
          expect(@new_invite).to be_present
        end

        it "should set its inviting_user to be the user who invited" do
          expect(@new_invite.inviting_user).to eql inviting_user
        end

        it "should set its invited_user to be the newly created user" do
          expect(@new_invite.invited_user).to eql @new_user
        end
      end
    end
  end

  describe '#confirm!' do
    let!(:user) { create :unconfirmed_user }

    def confirm_user!
      user.confirm!
    end

    before do
      KeyValue.create key: N2oFill::N2O_SIGN_UP_BONUS, value: 155
      TrackMixpanelEventJob.stub(:submit_job)
      PushCurrentN2oBalanceJob.stub(:submit_job)
    end

    context 'when confirmation fails' do
      before do
        create :user, email: "hey@email.com"
        user.update_attribute :email, "hey@email.com"
      end

      it 'does not perform any additional ops' do
        TrackMixpanelEventJob.should_not_receive(:submit_job).with('User Confirmed', user.id)
        UserMailer.should_not_receive(:welcome).with(user.email) { stub.as_null_object }
        user.should_not_receive(:mark_collaboration_invites_as_accepted!)
        expect {
          confirm_user!
        }.to_not change { user.reload.free_n2o }
      end
    end

    context 'new user confirming the email' do
      it 'gives sign up bonus if n2o_sign_up_bonus is defined in the key value db' do
        confirm_user!
        expect(user.reload.free_n2o).to eq 155
      end

      it 'marks collaboration invites as accepted' do
        user.should_receive(:mark_collaboration_invites_as_accepted!)
        confirm_user!
      end

      it 'sends the welcome email' do
        confirm_user!

        UserMailer.should_receive(:welcome).with(user.email) { stub.as_null_object }
        Delayed::Job.all.map(&:payload_object).map(&:perform)
      end

      context 'when a single invite exist for the user' do
        before do
          @invite = create :invite, invited_user: user, state: 'activated'
          confirm_user!
        end

        it 'is marked as accpted' do
          expect(@invite.reload.state).to eq 'accepted'
        end
      end

      context 'when multiple invites exist for the user' do
        before do
          @invite1 = create :invite, invited_user: user, state: 'activated'
          @invite2 = create :invite, invited_user: user, state: 'activated'
          confirm_user!
        end

        it 'oldest invite is marked as accpted' do
          expect(@invite1.reload.state).to eq 'accepted'
        end
      end
    end

    context 'existing user confirming the email' do
      before do
        create :n2o_fill, user: user, kind: N2oFill::Kind::SIGN_UP, amount: 100
      end

      it 'does not give any sign up bonus' do
        confirm_user!
        expect(user.reload.free_n2o).to eq 100
      end
    end

    it "tracks the 'User Confirmed' event on Mixpanel" do
      TrackMixpanelEventJob.should_receive(:submit_job).with('User Confirmed', user.id)
      confirm_user!
    end
  end

  describe '#able_to_login?' do
    it 'is true when user has username' do
      user = create :user
      user.should be_able_to_login
    end

    it 'is false when user does not have username' do
      user = build :external_authenticated_user
      user.save
      user.should_not be_able_to_login

      user.username = "mclovin123"
      user.save
      user.should be_able_to_login
    end
  end

  describe '#save' do
    context 'when username is missing' do
      context 'when external authentication is present' do
        it 'saves successfully' do
          user = build :external_authenticated_user
          user.should be_valid
          user.save

          user.reload
          user.email.should eq(user.email)
          user.authentications.first.provider.should eq("github")
        end

        context 'when we want to specifically validate the username' do
          it 'does not allow invalid username' do
            user = build :external_authenticated_user
            user.validate_confirmation = true
            user.should_not be_valid
          end
        end
      end

      context 'when user does not have any external authentication' do
        it 'fails to save' do
          user = build :user
          user.username = nil
          user.should_not be_valid
          expect {
            user.save
          }.to_not change { User.count }
        end
      end
    end
  end

  describe 'callbacks' do
    let(:user)  { build :user }

    it 'should set the authentication token' do
      user.save
      user.reload.authentication_token.should be_present
    end
  end

  describe '#token_for' do
    let!(:user) { create :user }

    before { create :authentication, user: user, provider: 'twitter', token: 'Tw1tt3rAcc355T0k3n' }

    context 'when an authentication object with access token for a given provider...' do
      context 'exists for this user' do
        before { create :authentication, user: user, provider: 'github', token: 'G17HubAcc355T0k3n' }

        it 'returns the access token' do
          user.token_for('github').should == 'G17HubAcc355T0k3n'
          user.token_for('twitter').should == 'Tw1tt3rAcc355T0k3n'
        end
      end

      context 'does not exist for this user' do
        it 'returns nil' do
          user.token_for('github').should be_nil
        end
      end
    end
  end

  describe '#visible_boxes' do
    it 'does not include boxes which was terminated more than 1 day ago' do
      user = create :user
      box1 = create :box, owner: user
      box2 = create :box, owner: user, terminated_at: 30.minutes.ago
      create :box, owner: user, terminated_at: 2.days.ago

      user.visible_boxes.should =~ [box1, box2]
    end
  end

  describe '#owned_invite_with_email' do
    it 'returns owned invite that has specified email' do
      user = create :user
      invite = create :invite, email: "test@email.com", inviting_user: user
      user.owned_invite_with_email("test@email.com").should eq(invite)
      user.owned_invite_with_email("not@there.com").should be_nil
    end
  end

  describe "#mark_collaboration_invites_as_accepted!" do
    let!(:user_1)   { create :user }
    let!(:user_2)   { create :user }
    let!(:box_1)    { create :box }
    let!(:box_2)    { create :box }

    let!(:ci_1)   { create :collaboration_invite, email: user_1.email, box: box_1 }
    let!(:ci_2)   { create :collaboration_invite, email: user_1.email, box: box_2 }
    let!(:ci_3)   { create :collaboration_invite, email: user_2.email, box: box_1 }

    it "should mark all collaboration invites meant for that user as 'accepted'" do
      user_1.mark_collaboration_invites_as_accepted!

      expect(ci_1.reload.state).to eq 'accepted'
      expect(ci_2.reload.state).to eq 'accepted'
      expect(ci_3.reload.state).to eq 'activated'
    end
  end

  describe ".clean_orphaned_users" do
    before do
      Timecop.freeze(10.days.ago) do
        @user1 = create :external_authenticated_user
      end
      Timecop.freeze(3.days.ago) do
        @user2 = create :external_authenticated_user
      end
      @user3 = create :user
    end

    it 'destroys old externally authenticated user' do
      User.clean_orphaned_users 5.days.ago
      User.where(id: @user1.id).should be_empty
      User.where(id: @user2.id).should be_present
      User.where(id: @user3.id).should be_present
    end
  end

  context 'when n2o is filled or allocated' do
    let(:user) { create :user }

    before do
      PushCurrentN2oBalanceJob.stub!(:submit_job)
    end

    it 'recalculates and updates balance' do
      # n2o fill creation invokes update_balance!
      expect(user.max_n2o).to eq 0
      expect(user.used_n2o).to eq 0
      expect(user.free_n2o).to eq 0

      fill = create :n2o_fill, user: user, amount:  200
      create :n2o_fill, user: user, amount: -150
      create :n2o_fill, user: user, amount:  500
      create :n2o_fill, amount:  100
      user.reload
      expect(user.max_n2o).to eq 550
      expect(user.used_n2o).to eq 0
      expect(user.free_n2o).to eq 550

      # n2o fill modification invokes update_balance!
      fill.update_attribute :amount, 100
      user.reload
      expect(user.max_n2o).to eq 450
      expect(user.used_n2o).to eq 0
      expect(user.free_n2o).to eq 450

      # n2o allocation creation invokes update_balance!
      alloc = create :n2o_allocation, user: user, amount: 100
      create :n2o_allocation, user: user, amount: 200
      create :n2o_allocation, user: user, amount: 50, deallocated_at: Date.today
      create :n2o_allocation, amount: 20
      user.reload
      expect(user.max_n2o).to eq 450
      expect(user.used_n2o).to eq 300
      expect(user.free_n2o).to eq 150

      alloc.deallocate!
      user.reload
      expect(user.max_n2o).to eq 450
      expect(user.used_n2o).to eq 200
      expect(user.free_n2o).to eq 250
    end

    it "sends a message to Pusher with the current user" do
      PushCurrentN2oBalanceJob.should_receive(:submit_job).with(user)
      user.update_balance!
    end
  end

  describe '#bonus' do
    context 'when user already has a bonus object associated to it' do
      let(:user) { create :user }
      let!(:bonus) { create :bonus, user: user }

      it 'returns the bonus object' do
        expect(user.bonus).to eq bonus
      end
    end

    context 'when user does not have a bonus object associated to it' do
      let(:user) { create :user }

      it 'creates one and returns it' do
        expect(Bonus.find_by_user_id user.id).to be_nil

        expect {
          user.bonus
        }.to change { Bonus.count }.by 1

        expect(user.bonus).to eq Bonus.last
      end
    end
  end

  describe "#active_for_authentication?" do
    let!(:user) { create :user }

    context 'is in private beta' do
      before { user.update_attribute(:in_private_beta, true) }

      it "should be true" do
        expect(user.active_for_authentication?).to be_true
      end
    end

    context 'is not in private beta' do
      before { user.update_attribute(:in_private_beta, false) }

      context 'when user is confirmed' do
        before { user.update_attribute(:confirmed_at, Time.now) }

        it "should be true" do
          expect(user.active_for_authentication?).to be_true
        end
      end

      context 'when user is not confirmed' do
        before { user.update_attribute(:confirmed_at, nil) }

        it "should be false" do
          expect(user.active_for_authentication?).to be_false
        end
      end
    end
  end

  describe "#fill_n2o!" do
    let!(:user) { create :user }

    it "should create an N2oFill object which belongs to the user" do
      expect {
        user.fill_n2o!(20, 1)
      }.to change(user.reload.n2o_fills, :count).by(1)
    end

    it "should fill the n2o_fill object with the right attributes" do
      user.fill_n2o!(20, 1)
      n2o_fill = user.n2o_fills.last

      expect(n2o_fill.amount).to eql 20
      expect(n2o_fill.kind).to eql 1
    end
  end

  describe "#fill_n2o_for_oauth_action!" do
    let!(:user) { create :user }

    context "with a valid provider" do
      let!(:kv)   { create :key_value, key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 20 }

      it "should create an n2o_fill object" do
        expect {
          user.fill_n2o_for_oauth_action!('google')
        }.to change(user.reload.n2o_fills, :count).by(1)

        n2o_fill = user.n2o_fills.last

        expect(n2o_fill.amount).to eql KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS]
        expect(n2o_fill.kind).to eql N2oFill::Kind::OAUTH_GOOGLE_CONNECT
      end

      it "should update the bonus object with the right attribute" do
        expect(user.bonus.google).to be_nil
        user.fill_n2o_for_oauth_action!('google')
        expect(user.bonus.reload.google).to be_present
      end
    end

    context "with an invalid provider" do
      it "should create an n2o_fill object" do
        expect {
          user.fill_n2o_for_oauth_action!('vimeo')
        }.to change(user.reload.n2o_fills, :count).by(0)
      end
    end
  end
end
