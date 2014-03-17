require 'spec_helper'

describe User do
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :email }
  it { should allow_mass_assignment_of :full_name }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :password_confirmation }
  it { should allow_mass_assignment_of :remember_me }
  it { should allow_mass_assignment_of :referrer_code }
  it { should allow_mass_assignment_of :coupon_code }
  it { should allow_mass_assignment_of :plan_group }
  it { should allow_mass_assignment_of :intent }

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
  it { should_not allow_mass_assignment_of :intro_seen }
  it { should_not allow_mass_assignment_of :team_plans_enabled }
  it { should_not allow_mass_assignment_of :created_at }
  it { should_not allow_mass_assignment_of :updated_at }

  it { should have_many(:authentications).dependent(:destroy) }
  it { should have_many(:box_users).dependent(:destroy) }
  it { should have_many(:boxes).through(:box_users) }
  it { should have_many(:snapshots).dependent(:nullify) }
  it { should have_many(:owned_boxes).class_name('Box').dependent(:nullify) }
  it { should have_many(:public_keys).dependent(:destroy) }
  it { should have_many(:oauth_applications).dependent(:destroy) }
  it { should have_many(:owned_invites).class_name('Invite').dependent(:nullify) }
  it { should have_many(:n2o_fills).dependent(:destroy) }
  it { should have_many(:n2o_allocations).dependent(:destroy) }
  it { should have_one(:bonus).dependent(:destroy) }
  it { should have_one(:user_profile).dependent(:destroy) }
  it { should have_one(:billing_profile).dependent(:destroy) }
  it { should have_one(:subscription).dependent(:destroy) }

  it { should belong_to(:plan_group) }

  describe 'validations' do
    let!(:user) { create :user }

    it { should validate_presence_of :username }
    it { should validate_presence_of :email }

    it { should validate_uniqueness_of :username }
    it { should validate_uniqueness_of :email }

    it { should ensure_length_of(:username).is_at_least(2).is_at_most(20) }
    it { should ensure_length_of(:full_name).is_at_least(0).is_at_most(40) }

    it { should allow_value(nil).for(:full_name) }

    describe '#username' do
      it 'validates uniqueness when the user has authentications' do
        user2 = build :external_authenticated_user
        user2.username = user.username
        expect(user2).not_to be_valid
      end

      it 'allows multiple users with nil username' do
        create :external_authenticated_user
        expect {
          expect(create(:external_authenticated_user)).to be_persisted
        }.not_to raise_error
      end

      it 'blocks some predefined usernames' do
        user = build :user
        expect(user).to be_valid
        %w(jobs actionio NitrousIO rOoT).each do |name|
          user.username = name
          expect(user).not_to be_valid
        end
      end

      it 'does not allow fancy characters' do
        user = build :user, username: "the-valid-On3"
        expect(user).to be_valid
        [
          "-wtf",
          "hello_world",
          "_invalid",
          "admin@hello",
          "god.mode.",
          "정찬옥",
          "dance like snake"
        ].each do |name|
          user.username = name
          expect(user).not_to be_valid
        end
      end
    end

    describe '#email' do
      it 'marks email addresses from fake accounts as invalid' do
        %w(mailinator.com noipmail.com deadaddress.com).each do |mail_provider|
          user = build :user, email: "test@#{mail_provider}"
          expect(user).not_to be_valid
        end
      end

      it 'marks email addresses with local part "spam" as invalid' do
        user = build :user, email: "spam@gmail.com"
        expect(user).not_to be_valid
      end


      it "checks for uniqueness for emails which have a +abc at the end of the username" do
        create :user, email: 'i@mclov.in'

        user_2 = build :user, email: 'i+1@mclov.in'
        expect(user_2).not_to be_valid

        user_3 = build :user, email: 'i+2@mclov.in'
        expect(user_3).not_to be_valid
      end
    end
  end

  describe "Callbacks" do
    let!(:user) { create :user }

    context "before destroy" do
      before do
        TrackMixpanelEventJob.stub(:submit_job)
        MailchimpJob.stub(:submit_job)
      end

      it "should archive user account's id, email, username, created_at and terminated_at" do
        Timecop.freeze do
          expect(DeletedUser).to receive(:create).with(user_id: user.id, email: user.email, username: user.username, created_at: user.created_at, deleted_at: Time.now)
          user.destroy
        end
      end

      it "should delete the user from Mixpanel" do
        Timecop.freeze do
          expect(DeleteMixpanelUserJob).to receive(:submit_job).with(user.email)
          user.destroy
        end
      end

      it "should remove the user from all Mailchimp mailing lists" do
        expect(MailchimpJob).to receive(:submit_job).with('unsubscribe', Settings.mailchimp_monthly_newsletter_list_id, email: user.email)
        expect(MailchimpJob).to receive(:submit_job).with('unsubscribe', Settings.mailchimp_product_announcements_list_id, email: user.email)
        user.destroy
      end
    end

    context "before save" do
      it "should set the referral code when created" do
        expect(SecureRandom).to receive(:urlsafe_base64).and_return("random_referral_code")
        user = create :user
        expect(user.referral_code).to eq('random_referral_code')
      end

      it 'should set the authentication token' do
        user = create :user
        expect(user.authentication_token).to be_present
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

  describe '#intent' do
    let!(:user) { create :user }

    it 'should parse its content as a nested query string to a hash' do
      user.intent = 'data%5Burl%5D=https%3A%2F%2Fgithub.com%2Frails%2Frails.git&kind=clone_repo'
      user.save
      expect(user.reload.intent[:kind]).to eql 'clone_repo'
      expect(user.reload.intent[:data][:url]).to eql 'https://github.com/rails/rails.git'
    end
  end

  describe '#clear_intent' do
    let!(:user) { create :user, intent: 'data%5Burl%5D=https%3A%2F%2Fgithub.com%2Frails%2Frails.git&kind=clone_repo' }

    it 'resets the intent to an empty hash' do
      user.clear_intent
      expect(user.intent).to eql({})
    end
  end

  describe '#confirm!' do
    let!(:user) { create :unconfirmed_user }

    def confirm_user!
      user.confirm!
    end

    before do
      KeyValue.create key: N2oFill::N2O_SIGN_UP_BONUS, value: 155
      KeyValue.create key: N2oFill::N2O_SIGN_UP_BONUS_EXTRA, value: 300
      TrackMixpanelEventJob.stub(:submit_job)
      PushCurrentN2oBalanceJob.stub(:submit_job)
      SetMixpanelPropertyJob.stub(:submit_job)
      MailchimpJob.stub(:submit_job)
    end

    context 'when confirmation fails' do
      before do
        create :user, email: "hey@email.com"
        user.update_attribute :email, "hey@email.com"
      end

      it 'does not perform any additional ops' do
        expect(TrackMixpanelEventJob).not_to receive(:submit_job).with('User Confirmed', user.id)
        expect(SetMixpanelPropertyJob).not_to receive(:submit_job).with(user.id, :confirmed_at, user.confirmed_at)

        expect(MailchimpJob).not_to receive(:submit_job)
        expect(user).not_to receive(:mark_collaboration_invites_as_accepted!)
        expect {
          confirm_user!
        }.to_not change { user.reload.free_n2o }
      end
    end

    context 'new user confirming email' do
      it 'gives sign up bonus if n2o_sign_up_bonus is defined in the key value db' do
        confirm_user!
        expect(user.reload.free_n2o).to eq 155
      end

      it 'marks collaboration invites as accepted' do
        expect(user).to receive(:mark_collaboration_invites_as_accepted!)
        confirm_user!
      end

      context 'when a single invite exist for the user' do
        before do
          @invite = create :invite, invited_user: user, state: 'activated'
          confirm_user!
        end

        it 'is marked as accepted' do
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

      it 'subscribes the user to all Mailchimp email lists' do
        expect(MailchimpJob).to receive(:submit_job).with('subscribe', Settings.mailchimp_monthly_newsletter_list_id, user_id: user.id)
        expect(MailchimpJob).to receive(:submit_job).with('subscribe', Settings.mailchimp_product_announcements_list_id, user_id: user.id)
        confirm_user!
      end

      it "tracks the 'User Confirmed' event on Mixpanel" do
        expect(TrackMixpanelEventJob).to receive(:submit_job).with('User Confirmed', user.id)
        confirm_user!
      end

      it "sets the property confirmed_at on User in Mixpanel" do
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :confirmed_at, an_instance_of(ActiveSupport::TimeWithZone))
        confirm_user!
      end
    end

    context 'existing user confirming the email' do
      let!(:user) { create :user_with_unconfirmed_new_email }

      before do
        create :n2o_fill, user: user, kind: N2oFill::Kind::SIGN_UP, amount: 100
      end

      it 'does not give any sign up bonus' do
        user.confirm!
        expect(user.reload.free_n2o).to eq 100
      end

      it 'updates the user in Mailchimp' do
        expect(MailchimpJob).to receive(:submit_job).with('subscribe', Settings.mailchimp_monthly_newsletter_list_id, user_id: user.id)
        expect(MailchimpJob).to receive(:submit_job).with('subscribe', Settings.mailchimp_product_announcements_list_id, user_id: user.id)
        user.confirm!
      end
    end

    it "tracks the 'User Confirmed' event on Mixpanel" do
      expect(TrackMixpanelEventJob).to receive(:submit_job).with('User Confirmed', user.id)
      confirm_user!
    end

    it "sets the property confirmed_at on User in Mixpanel" do
      expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :confirmed_at, an_instance_of(ActiveSupport::TimeWithZone))
      confirm_user!
    end
  end

  describe '#able_to_login?' do
    it 'is true when user has username' do
      user = create :user
      expect(user).to be_able_to_login
    end

    it 'is false when user does not have username' do
      user = build :external_authenticated_user
      user.save
      expect(user).not_to be_able_to_login

      user.username = "mclovin123"
      user.save
      expect(user).to be_able_to_login
    end
  end

  describe '#save' do
    context 'when username is missing' do
      context 'when external authentication is present' do
        it 'saves successfully' do
          user = build :external_authenticated_user
          expect(user).to be_valid
          user.save

          user.reload
          expect(user.email).to eq(user.email)
          expect(user.authentications.first.provider).to eq("github")
        end

        context 'when we want to specifically validate the username' do
          it 'does not allow invalid username' do
            user = build :external_authenticated_user
            user.validate_confirmation = true
            expect(user).not_to be_valid
          end
        end
      end

      context 'when user does not have any external authentication' do
        it 'fails to save' do
          user = build :user
          user.username = nil
          expect(user).not_to be_valid
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
      expect(user.reload.authentication_token).to be_present
    end

    context 'setting coupon code' do
      let!(:coupon) { create :coupon }

      context 'when given coupon code is active' do
        before do
          coupon.update_attribute 'active', true

          user.coupon_code = coupon.code
          user.save
        end

        it 'should save the user with the coupon code' do
          expect(user.reload.coupon_code).to eq(coupon.code)
        end
      end

      context 'when given coupon code is inactive' do
        before do
          coupon.update_attribute 'active', false

          user.coupon_code = coupon.code
          user.save
        end

        it 'should save the user without the coupon code' do
          expect(user.reload.coupon_code).to be_nil
        end
      end

      context 'when the given coupon code is active but in different case' do
        before do
          coupon.update_attributes(
            active: true,
            code: 'suchawesomeoffer'
          )

          user.coupon_code = 'SuchAwesomeOFFer'
          user.save
        end

        it 'should save the user with the correct coupon code' do
          expect(user.reload.coupon_code).to eq('suchawesomeoffer')
        end
      end

      context "when coupon code hasn't changed" do
        it 'should not try to find any active coupon codes' do
          expect(Coupon).not_to receive(:active)
          user.save
        end
      end
    end
  end

  describe '#token_for' do
    let!(:user) { create :user }

    before { create :authentication, user: user, provider: 'twitter', token: 'Tw1tt3rAcc355T0k3n' }

    context 'when an authentication object with access token for a given provider...' do
      context 'exists for this user' do
        before { create :authentication, user: user, provider: 'github', token: 'G17HubAcc355T0k3n' }

        it 'returns the access token' do
          expect(user.token_for('github')).to eq('G17HubAcc355T0k3n')
          expect(user.token_for('twitter')).to eq('Tw1tt3rAcc355T0k3n')
        end
      end

      context 'does not exist for this user' do
        it 'returns nil' do
          expect(user.token_for('github')).to be_nil
        end
      end
    end
  end

  describe '#visible_boxes' do
    let!(:user)         { create :user }
    let!(:another_user) { create :user }
    let!(:box1)         { create :box, owner: user }
    let!(:box2)         { create :box, owner: user, terminated_at: 30.minutes.ago }
    let!(:box3)         { create :box, owner: user, terminated_at: 2.days.ago }
    let!(:box4)         { create :box, owner: another_user, users: [user, another_user] }

    context 'when opts[:owner] is not present' do
      it "includes ALL boxes which haven't been terminated" do
        expect(user.visible_boxes).to eq([box1, box4])
      end
    end

    context 'when opts[:owner] is present' do
      it "includes only owned boxes which haven't been terminated" do
        expect(user.visible_boxes(owner: user)).to eq([box1])
      end
    end
  end

  describe '#eligible_for_coupon?' do
    let!(:user) { create :user }

    context 'when user has an active plan' do
      let!(:plan) { create :plan }
      before { user.stub(:active_plan).and_return(plan) }

      it 'returns false' do
        expect(user.eligible_for_coupon?).to eql false
      end
    end

    context "when user doesn't have an active plan" do
      before { user.stub(:active_plan).and_return(nil) }

      it 'returns true' do
        expect(user.eligible_for_coupon?).to eql true
      end
    end
  end

  describe '#twitter' do
    it 'memoizes and returns a new TwitterHandler instance' do
      mock_twitter = instance_double('TwitterHandler')
      user = create :user

      TwitterHandler.stub(:new) do |_user|
        expect(_user).to eq(user)
        mock_twitter
      end

      twitter = user.twitter
      expect(twitter).to eq(mock_twitter)
      expect(user.instance_variable_get(:@twitter)).to eq(mock_twitter)
    end
  end

  describe '#follow_nitrous_on_twitter' do
    it 'calls follow on Twitter handler instance' do
      mock_twitter = instance_double('TwitterHandler')
      user = create :user
      user.stub(:twitter) { mock_twitter }

      expect(mock_twitter).to receive(:follow)
      user.follow_nitrous_on_twitter
    end
  end

  describe '#send_tweet' do
    it 'calls tweet on Twitter handler instance' do
      mock_twitter = instance_double('TwitterHandler')
      user = create :user
      user.stub(:twitter) { mock_twitter }

      expect(mock_twitter).to receive(:tweet).with("I love Nitrous.IO")
      user.send_tweet "I love Nitrous.IO"
    end
  end

  describe '#owned_invite_with_email' do
    it 'returns owned invite that has specified email' do
      user = create :user
      invite = create :invite, email: "test@email.com", inviting_user: user
      expect(user.owned_invite_with_email("test@email.com")).to eq(invite)
      expect(user.owned_invite_with_email("not@there.com")).to be_nil
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
      expect(User.where(id: @user1.id)).to be_empty
      expect(User.where(id: @user2.id)).to be_present
      expect(User.where(id: @user3.id)).to be_present
    end
  end

  context 'when n2o is filled or allocated' do
    let(:user) { create :user }

    before do
      PushCurrentN2oBalanceJob.stub(:submit_job)
      SetMixpanelPropertyJob.stub(:submit_job)
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

    it "sends a push message to the user" do
      expect(PushCurrentN2oBalanceJob).to receive(:submit_job).with(user)
      user.update_balance!
    end

    it "updates Mixpanel with the free_n2o of the user" do
      expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :free_n2o, user.free_n2o)
      user.update_balance!
    end
  end

  describe '#bonus' do
    let(:user) { create :user }

    context 'when user already has a bonus object associated to it' do
      let!(:bonus) { create :bonus, user: user }

      it 'returns the bonus object' do
        expect(user.bonus).to eq bonus
      end
    end

    context 'when user does not have an associated bonus' do
      it 'creates one and returns it' do
        expect(Bonus.find_by_user_id user.id).to be_nil

        expect {
          user.bonus
        }.to change { Bonus.count }.by 1

        expect(user.bonus).to eq Bonus.last
      end
    end
  end

  describe '#user_profile' do
    let(:user) { create :user }

    context 'when user already has a user_profile object associated to it' do
      let!(:user_profile) { create :user_profile, user: user }

      it 'returns the user_profile object' do
        expect(user.user_profile).to eq user_profile
      end
    end

    context 'when user does not have an associated user_profile' do
      it 'creates one and returns it' do
        expect(UserProfile.find_by_user_id user.id).to be_nil

        expect {
          user.user_profile
        }.to change { UserProfile.count }.by 1

        expect(user.user_profile).to eq UserProfile.last
      end
    end
  end

  describe '#billing_profile' do
    let(:user) { create :user }

    context 'when user already has a billing_profile associated with it' do
      let!(:billing_profile) { create :billing_profile, user: user }

      it 'returns the billing_profile instance' do
        expect(user.billing_profile).to eq billing_profile
      end
    end

    context 'when user does not have an associated billing_profile' do
      it 'creates one and returns it' do
        expect(BillingProfile.find_by_user_id user.id).to be_nil

        expect {
          user.billing_profile
        }.to change { BillingProfile.count }.by 1

        expect(user.billing_profile).to eq BillingProfile.last
      end
    end
  end

  describe "#active_for_authentication?" do
    let!(:user) { create :user }

    it 'is false when user is banned from the site' do
      user.ban!
      expect(user).to_not be_active_for_authentication
    end

    context 'is in private beta' do
      before { user.update_attribute(:in_private_beta, true) }

      it "should be true" do
        expect(user.active_for_authentication?).to be_truthy
      end
    end

    context 'is not in private beta' do
      before { user.update_attribute(:in_private_beta, false) }

      context 'when user is confirmed' do
        before { user.update_attribute(:confirmed_at, Time.now) }

        it "should be true" do
          expect(user.active_for_authentication?).to be_truthy
        end
      end

      context 'when user is not confirmed' do
        before { user.update_attribute(:confirmed_at, nil) }

        it "should be false" do
          expect(user.active_for_authentication?).to be_falsey
        end
      end
    end
  end

  describe '#active_plan' do
    let!(:user) { create :user }

    context 'when user does not have a subscription' do
      it 'should return nil' do
        expect(user.active_plan).to be_nil
      end
    end

    context 'when user has a subscription but it is not active' do
      before do
        create :subscription, user: user, state: 'canceled'
      end

      it 'should return nil' do
        expect(user.active_plan).to be_nil
      end
    end

    context 'when user has an active subscription' do
      let!(:plan) { create :plan }
      let!(:subscription) { create :subscription, user: user, plan: plan, state: 'active' }

      it 'should return the subscription plan' do
        expect(user.active_plan).to eq(plan)
      end

      it 'memoizes the subscription plan' do
        expect(user.active_plan).to eq(plan)
        expect(user.instance_variable_get(:@active_plan)).to eq(plan)
      end
    end
  end

  describe '#subscription_pending' do
    let!(:user) { create :user }

    context 'when user does not have a subscription' do
      it 'returns false' do
        expect(user.subscription_pending).to eq(false)
      end
    end

    context 'when user has a non-pending subscription' do
      let!(:subscription) { create :subscription, user: user, state: 'active' }

      it 'returns false' do
        expect(user.subscription_pending).to eq(false)
      end
    end

    context 'when user has a pending subscription' do
      let!(:subscription) { create :subscription, user: user, state: 'pending' }

      it 'returns false' do
        expect(user.subscription_pending).to eq(true)
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

    context 'when user has invalid details' do
      before do
        user.update_attribute :username, "ha ha ha"
      end

      it "should sucessfully fill n2o" do
        expect {
          user.fill_n2o!(20, 1)
        }.to change(user.reload.n2o_fills, :count).by(1)
      end
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

  describe '#fill_n2o_for_chrome_app_installation!' do
    let!(:user) { create :user }

    before do
      create :key_value, key: N2oFill::N2O_INSTALL_CHROME_APP_BONUS, value: 10
      SetMixpanelPropertyJob.stub(:submit_job)
    end

    context 'when n2o has not yet been given for chrome app installation' do
      it 'sets chrome_app_installed on bonus table to current date' do
        expect(user.bonus.chrome_app).to be_nil
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :chrome_app_installed, true)

        Timecop.freeze do
          expect {
            user.fill_n2o_for_chrome_app_installation!
          }.to change { user.reload.n2o_fills.count }.by 1
          expect(user.bonus.reload.chrome_app.to_i).to eq Time.now.to_i
        end
        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eql 10
        expect(n2o_fill.kind).to eql N2oFill::Kind::INSTALL_CHROME_APP
      end
    end

    context 'when n2o has already been given for chrome app installation' do
      let!(:fill) { create :n2o_fill, user: user, kind: N2oFill::Kind::INSTALL_CHROME_APP }

      it 'does not do anything' do
        expect(SetMixpanelPropertyJob).not_to receive(:submit_job)
        expect {
          user.fill_n2o_for_chrome_app_installation!
        }.not_to change { user.reload.n2o_fills.count }
        expect(user.bonus.reload.chrome_app).to be_nil
      end
    end
  end

  describe '#fill_n2o_for_twitter_follow!' do
    let!(:user) { create :user }

    before do
      create :key_value, key: N2oFill::N2O_TWITTER_FOLLOW_BONUS, value: 5
      SetMixpanelPropertyJob.stub(:submit_job)
    end

    context 'when n2o has not yet been given for twitter follow' do
      it 'sets twitter_follow on bonus table to current date' do
        expect(user.bonus.twitter_follow).to be_nil
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :followed_on_twitter, true)

        Timecop.freeze do
          expect {
            user.fill_n2o_for_twitter_follow!
          }.to change { user.reload.n2o_fills.count }.by 1
          expect(user.bonus.reload.twitter_follow.to_i).to eq Time.now.to_i
        end
        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eql 5
        expect(n2o_fill.kind).to eql N2oFill::Kind::TWITTER_FOLLOW
      end
    end

    context 'when n2o has already been given for twitter follow' do
      let!(:fill) { create :n2o_fill, user: user, kind: N2oFill::Kind::TWITTER_FOLLOW }

      it 'does not do anything' do
        expect(SetMixpanelPropertyJob).not_to receive(:submit_job)
        expect {
          user.fill_n2o_for_twitter_follow!
        }.not_to change { user.reload.n2o_fills.count }
        expect(user.bonus.reload.twitter_follow).to be_nil
      end
    end
  end

  describe '#fill_n2o_for_tweet!' do
    let!(:user) { create :user }

    before do
      create :key_value, key: N2oFill::N2O_TWEET_SENT_BONUS, value: 5
      SetMixpanelPropertyJob.stub(:submit_job)
    end

    context 'when n2o has not yet been given for sending a tweet' do
      it 'sets tweet_sent on bonus table to current date' do
        expect(user.bonus.tweet_sent).to be_nil
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :sent_tweet_on_twitter, true)

        Timecop.freeze do
          expect {
            user.fill_n2o_for_tweet!
          }.to change { user.reload.n2o_fills.count }.by 1
          expect(user.bonus.reload.tweet_sent.to_i).to eq Time.now.to_i
        end
        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eql 5
        expect(n2o_fill.kind).to eql N2oFill::Kind::TWEET_SENT
      end
    end

    context 'when n2o has already been given for sending a tweet' do
      let!(:fill) { create :n2o_fill, user: user, kind: N2oFill::Kind::TWEET_SENT }

      it 'does not do anything' do
        expect(SetMixpanelPropertyJob).not_to receive(:submit_job)

        expect {
          user.fill_n2o_for_tweet!
        }.not_to change { user.reload.n2o_fills.count }
        expect(user.bonus.reload.tweet_sent).to be_nil
      end
    end
  end

  describe '#fill_n2o_for_business_survey!' do
    let!(:user) { create :user }

    before do
      create :key_value, key: N2oFill::N2O_BUSINESS_SURVEY_BONUS, value: 9
      SetMixpanelPropertyJob.stub(:submit_job)
    end

    context 'when n2o has not yet been given for completing the business survey' do
      it 'sets business_survey on bonus table to current date' do
        expect(user.bonus.business_survey).to be_nil
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :business_survey_completed, true)

        Timecop.freeze do
          expect {
            user.fill_n2o_for_business_survey!
          }.to change { user.reload.n2o_fills.count }.by 1
          expect(user.bonus.reload.business_survey.to_i).to eq Time.now.to_i
        end
        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eql 9
        expect(n2o_fill.kind).to eql N2oFill::Kind::BUSINESS_SURVEY
      end
    end

    context 'when n2o has already been awarded for completing the business survey' do
      let!(:fill) { create :n2o_fill, user: user, kind: N2oFill::Kind::BUSINESS_SURVEY }

      it 'does not do anything' do
        expect(SetMixpanelPropertyJob).not_to receive(:submit_job)
        expect {
          user.fill_n2o_for_business_survey!
        }.not_to change { user.reload.n2o_fills.count }
        expect(user.bonus.reload.business_survey).to be_nil
      end
    end
  end

  describe '#fill_n2o_for_user_survey_1!' do
    let!(:user) { create :user }

    before do
      create :key_value, key: N2oFill::N2O_USER_SURVEY_1_BONUS, value: 10
      SetMixpanelPropertyJob.stub(:submit_job)
    end

    context 'when n2o has no yet been given for completing user survey #1' do
      it 'sets user_survey_1 on bonus table to current date' do
        expect(user.bonus.user_survey_1).to be_nil
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :user_survey_1_completed, true)

        Timecop.freeze do
          expect {
            user.fill_n2o_for_user_survey_1!
          }.to change { user.reload.n2o_fills.count}.by 1
          expect(user.bonus.reload.user_survey_1.to_i).to eq Time.now.to_i
        end
        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eql 10
        expect(n2o_fill.kind).to eql N2oFill::Kind::USER_SURVEY_1
      end
    end

    context 'when n2o has already been awarded for completing user survey #1' do
      let!(:fill) { create :n2o_fill, user: user, kind: N2oFill::Kind::USER_SURVEY_1 }

      it 'does not do anything' do
        expect(SetMixpanelPropertyJob).not_to receive(:submit_job)
        expect {
          user.fill_n2o_for_user_survey_1!
        }.not_to change { user.reload.n2o_fills.count }
        expect(user.bonus.reload.user_survey_1).to be_nil
      end
    end
  end

  describe "public keys <-> box jobs" do
    let!(:user) { create :user }
    let!(:box)  { create :box, owner: user }

    let!(:pk_1) { create :public_key, key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh #{user.email}", user: user }
    let!(:pk_2) { create :public_key, key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSx #{user.email}", user: user }
    # This key will not be added/removed
    let!(:pk_3) { create :public_key, key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh test@nitrous.io' }

    describe "#add_all_public_keys_to_box" do
      it "should add all public keys belonging to the user to the box" do
        expect(AddPublicKeyToBoxJob).to receive(:submit_job).with(box.id, pk_1.key)
        expect(AddPublicKeyToBoxJob).to receive(:submit_job).with(box.id, pk_2.key)

        user.add_all_public_keys_to_box(box)
      end
    end

    describe "#remove_all_public_keys_from_box" do
      it "should add all public keys belonging to the user from the box" do
        expect(RemovePublicKeyFromBoxJob).to receive(:submit_job).with(box.id, pk_1.key)
        expect(RemovePublicKeyFromBoxJob).to receive(:submit_job).with(box.id, pk_2.key)

        user.remove_all_public_keys_from_box(box)
      end
    end
  end

  describe '#subscribe' do
    let!(:user) { create :user }
    let!(:plan) { create :plan }

    context 'when user has an active subscription' do
      before do
        create :subscription, user: user, state: 'active'
      end

      it 'should add an error and return false' do
        expect(user.subscribe plan, 'abcd').to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

    context 'when user doesnt have an active subscription' do
      let(:customer) { double('Stripe::Customer') }

      context 'when no stripe_token is given' do
        it 'should add an error and return false' do
          expect(user.subscribe plan, nil).to be_falsey
          expect(user.errors.messages).to include(:base)
        end
      end

      context 'when no plan is given' do
        it 'should add an error and return false' do
          expect(user.subscribe nil, 'stripe_token').to be_falsey
          expect(user.errors.messages).to include(:base)
        end
      end

      context 'user has a Stripe profile' do
        before do
          user.stub(:stripe_customer_id) { 'cus_001' }
          customer.stub(:id) { 'customer_001' }

          user.stub(:save_stripe_card_to_billing_profile)
          PushBillingProfileUpdatedJob.stub(:submit_job)

          expect(ChargeOverdueInvoicesJob).to receive(:submit_job).with('cus_001')
        end

        context 'user has a coupon code' do
          let!(:coupon) { create :coupon }
          before { user.coupon_code = coupon.code }

          context 'when given coupon code is active' do
            before do
              coupon.update_attribute 'active', true
            end

            it 'should retrieve Stripe profile for the given customer id; then update it setting the email, description, card, plan and coupon' do
              expect(Stripe::Customer).to receive(:retrieve).with('cus_001') { customer }
              expect(customer).to receive(:email=).with(user.email)
              expect(customer).to receive(:description=).with("#{user.email} #{user.username}")
              expect(customer).to receive(:card=).with('stripe_token')
              expect(customer).to receive(:plan=).with(plan.stripe_id)
              expect(customer).to receive(:coupon=).with(user.coupon_code)
              expect(customer).to receive(:save)

              user.subscribe plan, 'stripe_token'
            end
          end

          context 'when given coupon code has expired' do
            before do
              coupon.update_attribute 'active', false
            end

            it "should not set coupon code on user's Stripe profile" do
              allow(Stripe::Customer).to receive(:retrieve).with('cus_001') { customer }
              allow(customer).to receive(:email=)
              allow(customer).to receive(:description=)
              allow(customer).to receive(:card=)
              allow(customer).to receive(:plan=)
              allow(customer).to receive(:save)

              expect(customer).not_to receive(:coupon=)
              user.subscribe plan, 'stripe_token'
            end
          end
        end

        context 'user does not have a coupon code' do
          it "should not set coupon code on user's Stripe profile" do
            allow(Stripe::Customer).to receive(:retrieve).with('cus_001') { customer }
            allow(customer).to receive(:email=)
            allow(customer).to receive(:description=)
            allow(customer).to receive(:card=)
            allow(customer).to receive(:plan=)
            allow(customer).to receive(:save)

            expect(customer).not_to receive(:coupon=)

            user.subscribe plan, 'stripe_token'
          end
        end
      end

      context "user hasn't got a Stripe profile" do
        before do
          customer.stub(:id) { 'customer_001' }

          PushBillingProfileUpdatedJob.stub(:submit_job)
          user.stub(:save_stripe_card_to_billing_profile)
        end

        it "should create a new Stripe customer with user's email, description, card, plan and coupon" do
          expect(Stripe::Customer).to receive(:create).with({
            email: user.email,
            description: "#{user.email} #{user.username}",
            card: 'stripe_token',
            plan: plan.stripe_id,
            coupon: user.coupon_code
          }).and_return customer

          user.subscribe plan, 'stripe_token'
        end

        context 'user has a coupon code' do
          let!(:coupon) { create :coupon }
          before { user.coupon_code = coupon.code }

          context 'when given coupon code is active' do
            before do
              coupon.update_attribute 'active', true
            end

            it "should create a new Stripe customer with user's email, description, card, plan and coupon" do
              expect(Stripe::Customer).to receive(:create).with({
                email: user.email,
                description: "#{user.email} #{user.username}",
                card: 'stripe_token',
                plan: plan.stripe_id,
                coupon: user.coupon_code
              }).and_return customer

              user.subscribe plan, 'stripe_token'
            end
          end

          context 'when given coupon code has expired' do
            before do
              coupon.update_attribute 'active', false
            end

            it "should create a new Stripe customer with user's email, description, card, plan, and coupon set to nil" do
              expect(Stripe::Customer).to receive(:create).with({
                email: user.email,
                description: "#{user.email} #{user.username}",
                card: 'stripe_token',
                plan: plan.stripe_id,
                coupon: nil
              }).and_return customer

              user.subscribe plan, 'stripe_token'
            end
          end
        end

        context 'user does not have a coupon code' do
          it "should create a new Stripe customer with user's email, description, card, plan, and coupon set to nil" do
            expect(Stripe::Customer).to receive(:create).with({
              email: user.email,
              description: "#{user.email} #{user.username}",
              card: 'stripe_token',
              plan: plan.stripe_id,
              coupon: nil
            }).and_return customer

            user.subscribe plan, 'stripe_token'
          end
        end
      end

      context 'after successfully creating or updating a customer in Stripe' do
        before do
          customer.stub(:id) { 'customer_001' }
          customer.stub_chain('cards.data.first.last4') { '1234' }
          customer.stub_chain('cards.data.first.type') { 'visa' }
          customer.stub_chain('cards.data.first.exp_month') { 12 }
          customer.stub_chain('cards.data.first.exp_year') { 2014 }
          Stripe::Customer.stub(:create) { customer }

          PushBillingProfileUpdatedJob.stub(:submit_job)
        end

        it "updates user's billing profile" do
          user.subscribe plan, 'stripe_token'

          expect(user.reload.billing_profile.last_four).to eq('1234')
          expect(user.reload.billing_profile.card_type).to eq('visa')
          expect(user.reload.billing_profile.exp_month).to eq(12)
          expect(user.reload.billing_profile.exp_year).to eq(2014)
        end

        it 'stores the stripe customer id' do
          user.subscribe plan, 'stripe_token'

          expect(user.reload.stripe_customer_id).to eq('customer_001')
        end

        it 'submits a job to push billing profile update message' do
          expect(PushBillingProfileUpdatedJob).to receive(:submit_job).with(user.id)
          user.subscribe plan, 'stripe_token'
        end
      end

      context 'when there is a Stripe::CardError' do
        before do
          Stripe::Customer.stub(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
        end

        it 'should add an error and return false' do
          expect(user.subscribe plan, 'stripe_token').to be_falsey
          expect(user.errors.messages).to include(:base)
        end

        it "should not update the user's billing profile" do
          expect(user.billing_profile).not_to receive(:save)
          expect(user.reload.billing_profile.last_four).to be_nil
          expect(user.reload.billing_profile.card_type).to be_nil
          expect(user.reload.billing_profile.exp_month).to be_nil
          expect(user.reload.billing_profile.exp_year).to be_nil
        end
      end

      context 'when there is a Stripe::CardError with a code of "card_declined"' do
        before do
          Stripe::Customer.stub(:create).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
        end

        it 'should add an error with a message about contacting the bank and return false' do
          expect(user.subscribe plan, 'stripe_token').to be_falsey
          expect(user.errors.messages[:base][0]).to match 'Try contacting your bank directly for assistance'
        end
      end
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::Customer.stub(:create).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and return false' do
        expect(user.subscribe plan, 'stripe_token').to be_falsey
        expect(user.errors.messages).to include(:base)
      end

      it "should not update the user's billing profile" do
        expect(user.billing_profile).not_to receive(:save)
        expect(user.reload.billing_profile.last_four).to be_nil
        expect(user.reload.billing_profile.card_type).to be_nil
        expect(user.reload.billing_profile.exp_month).to be_nil
        expect(user.reload.billing_profile.exp_year).to be_nil
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::Customer.stub(:create).and_raise(Stripe::StripeError) }

      it 'should add an error and return false' do
        expect(user.subscribe plan, 'stripe_token').to be_falsey
        expect(user.errors.messages).to include(:base)
      end

      it "should not update the user's billing profile" do
        expect(user.billing_profile).not_to receive(:save)
        expect(user.reload.billing_profile.last_four).to be_nil
        expect(user.reload.billing_profile.card_type).to be_nil
        expect(user.reload.billing_profile.exp_month).to be_nil
        expect(user.reload.billing_profile.exp_year).to be_nil
      end
    end
  end

  describe '#apply_subscription' do
    let!(:user) { create :user }
    let!(:existing_plan) { create :plan }
    let!(:new_plan) { create :plan }

    context 'when user already has an associated subscription in active state' do
      let!(:subscription) { create :subscription, user: user, plan: existing_plan, state: 'active' }

      it 'should not activate the subscription again' do
        expect(user.subscription).not_to receive(:activate!)
        user.apply_subscription(new_plan)
      end
    end

    context 'when user already has an associated subscription in canceled state' do
      let!(:subscription) { create :subscription, user: user, plan: existing_plan, state: 'canceled' }

      it "should set the subscription's plan to the given plan" do
        user.apply_subscription(new_plan)
        expect(user.subscription.plan).to eq(new_plan)
      end

      it 'should activate the subscription' do
        expect(user.subscription).to receive(:activate!)
        user.apply_subscription(new_plan)
      end
    end

    context 'when user does not have a subscription' do
      it 'should build a new subscription with the given plan' do
        expect {
          user.apply_subscription(new_plan)
        }.to change { Subscription.count }.by(1)

        expect(user.reload.subscription.plan).to eq(new_plan)
      end

      it 'should activate the new subscription' do
        user.apply_subscription(new_plan)
        expect(user.reload.subscription.state).to eq('active')
      end
    end
  end

  describe '#change_plan' do
    let!(:user) { create :user, stripe_customer_id: 'cus_fake' }
    let!(:existing_plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, plan: existing_plan }

    context 'when the given plan is different from their existing plan' do
      let!(:new_plan) { create :plan }
      let!(:customer) { double }

      context "and it's a price downgrade from existing plan" do
        before do
          new_plan.stub(:is_price_downgrade_from) { true }
        end

        it 'should call downgrade plan' do
          expect(user).to receive(:downgrade_plan).with(new_plan)
          user.change_plan new_plan
        end
      end

      context "and it's a price upgrade from existing plan" do
        before do
          new_plan.stub(:is_price_downgrade_from) { false }
        end

        it 'should call upgrade plan' do
          expect(user).to receive(:upgrade_plan).with(new_plan)
          user.change_plan new_plan
        end
      end
    end

    context 'when the given plan is the same as the existing plan' do
      it 'should return false' do
        expect(user.change_plan(existing_plan)).to be_falsey
      end
    end

    context 'when a plan is not given' do
      it 'should return false' do
        expect(user.change_plan(nil)).to be_falsey
      end
    end
  end

  describe '#upgrade_plan' do
    let!(:user) { create :user, stripe_customer_id: 'cus_fake' }
    let!(:existing_plan) { create :plan }
    let!(:new_plan) { create :plan, price: 20 }

    let!(:subscription) { create :subscription, user: user, plan: existing_plan }
    let!(:invoice) { double 'Stripe::Invoice' }

    before do
      Stripe::InvoiceItem.stub(:create)
      Stripe::Invoice.stub(:create) { invoice }
      invoice.stub(:pay)
      invoice.stub(:id) { 'inv_001' }
    end

    it 'creates a new invoice item with the charge for the new plan' do
      expect(Stripe::InvoiceItem).to receive(:create).with({
        customer: 'cus_fake',
        amount: new_plan.price_in_cents,
        currency: 'usd',
        description: "Subscription to #{new_plan.name} (#{new_plan.price}/month)"
      })

      user.upgrade_plan new_plan
    end

    it 'creates and attempts to pay a new invoice' do
      expect(Stripe::Invoice).to receive(:create).with({
        customer: 'cus_fake'
      }).and_return { invoice }

      expect(invoice).to receive(:pay)

      user.upgrade_plan new_plan
    end

    it "saves the pending plan and Stripe invoice id in subscription" do
      Stripe::Invoice.stub(:create) { invoice }
      user.upgrade_plan new_plan

      expect(user.subscription.reload.pending_plan_id).to eq(new_plan.id)
      expect(user.subscription.reload.stripe_invoice_id).to eq(invoice.id)
    end

    context 'when there is a Stripe::CardError' do
      before do
        Stripe::Invoice.stub(:create) { invoice }
        expect(invoice).to receive(:pay).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_error_code', message: 'stripe error' }})
        TrackMixpanelEventJob.stub(:submit_job)
      end

      it 'should add an error and return false' do
        expect(user.upgrade_plan new_plan).to be_falsey
        expect(user.errors.messages).to include(:base)
      end

      it 'should not update the subscription' do
        expect {
          user.upgrade_plan new_plan
        }.to_not change {  subscription.reload.stripe_invoice_id }
      end

      it 'should track the error in Mixpanel' do
        expect(TrackMixpanelEventJob).to receive(:submit_job).with('Upgrade Plan Failed (Credit Card Error)', user.id, 'card_error_code')
        user.upgrade_plan new_plan
      end
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::InvoiceItem.stub(:create).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and return false' do
        expect(user.upgrade_plan new_plan).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::InvoiceItem.stub(:create).and_raise(Stripe::StripeError) }

      it 'should add an error and return false' do
        expect(user.upgrade_plan new_plan).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

  end

  describe '#downgrade_plan' do
    let!(:user) { create :user, stripe_customer_id: 'cus_fake' }
    let!(:existing_plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, plan: existing_plan }

    let!(:new_plan) { create :plan }

    context 'when the user is allowed to change to the new plan' do
      before do
        user.stub(:can_downgrade_to_plan?).with(new_plan) { true }
      end

      it 'should send a request to Stripe to change to new plan' do
        expect(user).to receive(:change_plan_in_stripe).with(new_plan)
        user.downgrade_plan(new_plan)
      end
    end

    context 'when the user is not allowed to change to the new plan' do
      before do
        user.stub(:can_downgrade_to_plan?).with(new_plan) { false }
      end

      it 'should not send a request to Stripe to change the plan' do
        expect(user).not_to receive(:change_plan_in_stripe).with(new_plan)
        user.downgrade_plan(new_plan)
      end

      it 'should add an error and return false' do
        expect(user.downgrade_plan(new_plan)).to be_falsey
        expect(user.errors.messages[:base][0]).to match 'You need to terminate boxes'
      end
    end
  end

  describe '#process_pending_upgrade' do
    let!(:user) { create :user }
    let!(:plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, pending_plan: plan, stripe_invoice_id: 'inv_001' }

    context 'when theres no subscription for the user' do
      before { user.stub(:subscription) { nil } }

      it 'should not call change_plan_in_stripe' do
        expect(user).not_to receive(:change_plan_in_stripe)
        user.process_pending_upgrade 'inv_001'
      end
    end

    context 'when the stripe invoice id for the pending plan change matches the given stripe invoice id' do
      it 'should call change_plan_in_stripe with the pending plan and a trial end date of 1 month from today' do
        Timecop.freeze do
          expect(user).to receive(:change_plan_in_stripe).with(plan, 1.month.since.to_i)
          user.process_pending_upgrade 'inv_001'
        end
      end

      it 'should clear the pending plan and stripe invoice id from the subscription' do
        user.process_pending_upgrade 'inv_001'
        expect(subscription.reload.pending_plan_id).to eq(nil)
        expect(subscription.reload.stripe_invoice_id).to eq(nil)
      end
    end

    context 'when the stripe invoice id for the pending plan change doesnt match the given stripe invoice id' do
      it 'should not call update subscription' do
        expect(user).not_to receive(:change_plan_in_stripe)
        user.process_pending_upgrade 'inv_002'
      end

      it 'should not clear the pending plan and stripe invoice id from the subscription' do
        user.process_pending_upgrade 'inv_002'
        expect(subscription.reload.pending_plan_id).to eq(plan.id)
        expect(subscription.reload.stripe_invoice_id).to eq('inv_001')
      end
    end
  end

  describe '#clear_pending_upgrade' do
    let!(:user) { create :user }
    let!(:plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, pending_plan: plan, stripe_invoice_id: 'inv_001'  }

    context 'when theres no subscription for the user' do
      before { user.stub(:subscription) { nil } }

      it 'should not send a notice to user informing the payment failure' do
        expect(SubscriptionMailer).not_to receive(:upgrade_failed_alert)
        user.clear_pending_upgrade 'inv_001'
      end
    end

    context "when the stripe invoice id for the pending plan change matches the given stripe invoice id" do
      it 'sends a notice to user informing the payment failure' do
        expect(SubscriptionMailer).to receive(:upgrade_failed_alert).with(user, subscription.pending_plan) { double.as_null_object }
        user.clear_pending_upgrade 'inv_001'
        Delayed::Job.last.invoke_job
      end

      it 'should clear the pending plan and stripe invoice id from the subscription' do
        user.clear_pending_upgrade 'inv_001'
        expect(subscription.reload.pending_plan_id).to eq(nil)
        expect(subscription.reload.stripe_invoice_id).to eq(nil)
      end
    end

    context "when the stripe invoice id for the pending plan change doesnt match the given stripe invoice id" do
      it 'should not clear the pending plan and stripe invoice id from the subscription' do
        user.clear_pending_upgrade 'inv_002'
        expect(subscription.reload.pending_plan_id).to eq(plan.id)
        expect(subscription.reload.stripe_invoice_id).to eq('inv_001')
      end
    end
  end

  describe '#change_plan_in_stripe' do
    let!(:user) { create :user, stripe_customer_id: 'cus_fake' }
    let!(:plan) { create :plan, stripe_id: 'plan_stripe_id' }

    context 'when Stripe customer record does not exist' do
      before do
        Stripe::Customer.stub(:retrieve).with('cus_fake') { nil }
      end

      it 'should add an error and return false' do
        expect(user.change_plan_in_stripe(plan, 1387277143)).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

    context 'when Stripe customer record exists' do
      let!(:customer) { double('Stripe::Customer') }

      before do
        Stripe::Customer.stub(:retrieve).with('cus_fake') { customer }
      end

      it 'should send an update subscription request with new plan id and trial end date' do
        expect(customer).to receive(:update_subscription).with(plan: 'plan_stripe_id', trial_end: 1387277143)
        user.change_plan_in_stripe(plan, 1387277143)
      end
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::Customer.stub(:retrieve).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and return false' do
        expect(user.change_plan_in_stripe(plan, nil)).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::Customer.stub(:retrieve).and_raise(Stripe::StripeError) }

      it 'should add an error and return false' do
        expect(user.change_plan_in_stripe(plan, nil)).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end
  end

  describe '#apply_change_plan' do
    let!(:user) { create :user }
    let!(:current_plan) { create :plan }
    let!(:new_plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, plan: current_plan, state: 'active' }

    context "when the user's subscription is not in active state" do
      before { user.subscription.stub(:active?).and_return(false) }

      it 'should return false' do
        expect(user.apply_plan_change new_plan).to be_falsey
      end
    end

    context "when the user's subcription is in active state" do
      let!(:new_subscription) { create :subscription }

      it 'should call the change_plan on subscription' do
        expect(user.subscription).to receive(:change_plan!).with(new_plan)
        user.apply_plan_change(new_plan)
      end
    end
  end

  describe '#cancel_subscription' do
    let!(:user) { create :user, stripe_customer_id: 'cus_fake' }
    let!(:plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, plan: plan, state: 'active' }

    context "when the user's subscription is in the pending state" do
      before { user.subscription.stub(:pending?).and_return(true) }

      it 'should add an error and return false' do
        expect(user.cancel_subscription).to be_falsey
        expect(user.errors.messages[:base][0]).to match 'You do not have an active subscription'
      end
    end

    context "when the user's subscription is in the canceled state" do
      before { user.subscription.stub(:canceled?).and_return(true) }

      it 'should add an error and return false' do
        expect(user.cancel_subscription).to be_falsey
        expect(user.errors.messages[:base][0]).to match 'You do not have an active subscription'
      end
    end

    context "when user can't cancel their plan" do
      before do
        user.stub(:can_cancel_plan?) { false }
      end

      it 'should add an error and return false' do
        expect(user.cancel_subscription).to be_falsey
        expect(user.errors.messages[:base][0]).to match 'You need to terminate boxes'
      end
    end

    context 'when user can cancel their plan' do
      before do
        user.stub(:can_cancel_plan?) { true }
      end

      context 'and a Stripe customer record does not exist' do
        before do
          Stripe::Customer.stub(:retrieve).with('cus_fake') { nil }
        end

        it 'should add an error and return false' do
          expect(user.cancel_subscription).to be_falsey
          # Brittle test below but YOLO. Plus we need to differentiate this
          # error message from the one in the other test.
          expect(user.errors.messages[:base][0]).to match 'It looks like you do not have a subscription'
        end
      end

      context 'and a Stripe customer record exists' do
        let!(:customer) { double('Stripe::Customer') }

        before do
          Stripe::Customer.stub(:retrieve).with('cus_fake') { customer }
        end

        it 'cancels the subscription in Stripe' do
          user.subscription.stub(:cancel!)
          DowngradeBoxesJob.stub(:submit_job)

          expect(customer).to receive(:cancel_subscription)
          user.cancel_subscription
        end

        it "cancels the user's associated subscription" do
          customer.stub(:cancel_subscription)
          DowngradeBoxesJob.stub(:submit_job)

          expect(user.subscription).to receive(:cancel!)
          user.cancel_subscription
        end

        it "undelinquents user" do
          customer.stub(:cancel_subscription)
          DowngradeBoxesJob.stub(:submit_job)

          expect(user).to receive(:undelinquent!)
          user.cancel_subscription
        end

        it "starts a job to downgrade the user's boxes" do
          user.subscription.stub(:cancel!)
          customer.stub(:cancel_subscription)

          expect(DowngradeBoxesJob).to receive(:submit_job).with(user.id)
          user.cancel_subscription
        end
      end
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::Customer.stub(:retrieve).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and return false' do
        expect(user.cancel_subscription).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::Customer.stub(:retrieve).and_raise(Stripe::StripeError) }

      it 'should add an error and return false' do
        expect(user.cancel_subscription).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end
  end

  describe '#can_downgrade_to_plan?' do
    let!(:user) { create :user }
    let!(:existing_plan) { create :plan, n2o_amount: 1200 }
    let!(:subscription) { create :subscription, user: user, plan: existing_plan }

    context 'when new plan has more n2o than the current plan' do
      let!(:new_plan) { create :plan, n2o_amount: 2500 }

      it 'should return true' do
        expect(user.can_downgrade_to_plan?(new_plan)).to eq(true)
      end
    end

    context 'when new plan has less n2o than the current plan' do
      let!(:new_plan) { create :plan, n2o_amount: 600 }

      context 'when user has used more n2o than new plan gives' do
        before do
          user.max_n2o = 1350 # "Base" n2o = 150. TODO: Add an accessor for this.
          user.used_n2o = 800
        end

        it 'should return false' do
          expect(user.can_downgrade_to_plan?(new_plan)).to eq(false)
        end
      end

      context 'when user has used less n2o than new plan gives' do
        before do
          user.max_n2o = 1350
          user.used_n2o = 100
        end

        it 'should return true' do
          expect(user.can_downgrade_to_plan?(new_plan)).to eq(true)
        end
      end

      context 'when user has used the same n2o as what the new plan gives' do
        before do
          user.max_n2o = 1350
          user.used_n2o = 750
        end

        it 'should return true' do
          expect(user.can_downgrade_to_plan?(new_plan)).to eq(true)
        end
      end
    end
  end

  describe '#can_cancel_plan?' do
    let!(:user) { create :user }
    let!(:existing_plan) { create :plan, n2o_amount: 1200 }
    let!(:subscription) { create :subscription, user: user, plan: existing_plan }

    context 'when user has used more n2o than they would have after canceling' do
      before do
        user.max_n2o = 1350
        user.used_n2o = 1300
      end

      it 'returns false' do
        expect(user.can_cancel_plan?).to eq(false)
      end
    end

    context 'when user has used less n2o than as they would have after canceling' do
      before do
        user.max_n2o = 1350
        user.used_n2o = 100
      end

      it 'returns true' do
        expect(user.can_cancel_plan?).to eq(true)
      end
    end

    context 'when user has used the same n2o as they would have after canceling' do
      before do
        user.max_n2o = 1350
        user.used_n2o = 150
      end

      it 'returns true' do
        expect(user.can_cancel_plan?).to eq(true)
      end
    end
  end

  describe '#change_card' do
    let!(:user) { create :user, stripe_customer_id: 'stripe_customer_id' }
    let!(:customer) { double }

    before do
      Stripe::Customer.stub(:retrieve).with(user.stripe_customer_id) { customer }
      customer.stub(:card=).with('stripe_token')
      customer.stub(:save)
      customer.stub_chain('cards.data.first.last4') { '1234' }
      customer.stub_chain('cards.data.first.type') { 'visa' }
      customer.stub_chain('cards.data.first.exp_month') { 12 }
      customer.stub_chain('cards.data.first.exp_year') { 2014 }
      PushBillingProfileUpdatedJob.stub(:submit_job)
    end

    context 'when valid card details are provided' do
      it 'changes the card in Stripe and saves card details to the associated billing profile' do
        expect(customer).to receive(:card=).with('stripe_token')
        expect(customer).to receive(:save)

        user.change_card('stripe_token')

        expect(user.reload.billing_profile.last_four).to eq('1234')
        expect(user.reload.billing_profile.card_type).to eq('visa')
        expect(user.reload.billing_profile.exp_month).to eq(12)
        expect(user.reload.billing_profile.exp_year).to eq(2014)
      end

      it 'send an email to the user notifying the card change' do
        expect {
          user.change_card('stripe_token')
        }.to change(Delayed::Job, :count)

        expect(Delayed::Job.first.handler).to match(/'SubscriptionMailer'\nmethod_name: :credit_card_changed_alert\nargs:\n- #{user.id}\n/)
      end

      it 'submits a job to push billing profile updated message' do
        expect(PushBillingProfileUpdatedJob).to receive(:submit_job).with(user.id)
        user.change_card('stripe_token')
      end

      it 'submits a job to charge overdue invoices' do
        expect(ChargeOverdueInvoicesJob).to receive(:submit_job).with(user.stripe_customer_id)
        user.change_card('stripe_token')
      end
    end

    context 'when there is a Stripe::CardError' do
      before do
        expect(customer).to receive(:card=).with('stripe_token')
        expect(customer).to receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
      end

      it 'should add an error and return false' do
        expect(user.change_card('stripe_token')).to be_falsey
        expect(user.errors.messages).to include(:base)
      end

      it 'should not update the billing profile' do
        expect {
          user.change_card('stripe_token')
        }.to_not change {  user.reload.billing_profile }
      end

      it 'does not send an email to the user notifying the card change' do
        expect(SubscriptionMailer).not_to receive(:delay)
        user.change_card('stripe_token')
      end

      it 'does not submit a job to push billing profile updated message' do
        expect(PushBillingProfileUpdatedJob).not_to receive(:submit_job).with(user.id)
        user.change_card('stripe_token')
      end
    end

    context 'when there is a Stripe::CardError with a code of "card_declined"' do
      before do
        expect(customer).to receive(:card=).with('stripe_token')
        expect(customer).to receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
      end

      it 'should add an error with a message about contacting the bank and return false' do
        expect(user.change_card('stripe_token')).to be_falsey
        expect(user.errors.messages[:base][0]).to match 'Try contacting your bank directly for assistance'
      end
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::Customer.stub(:retrieve).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and return false' do
        expect(user.change_card('stripe_token')).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::Customer.stub(:retrieve).and_raise(Stripe::StripeError) }

      it 'should add an error and return false' do
        expect(user.change_card('stripe_token')).to be_falsey
        expect(user.errors.messages).to include(:base)
      end
    end
  end

  describe '#ban!' do
    let!(:user) { create :user, password: '123456', reset_password_token: 'foobar', reset_password_sent_at: 1.hour.ago }
    let!(:box_1) { create :box, owner: user, state: 'stopped' }
    let!(:box_2) { create :box, owner: user, state: 'running' }
    let!(:box_3) { create :box, owner: user, state: 'running' }
    let!(:n2o_fill1) { create :n2o_fill, user: user, amount: 200 }
    let!(:n2o_fill2) { create :n2o_fill, user: user, amount: 300 }
    let!(:mock_coach) { instance_double('Coach') }

    before do
      allow_any_instance_of(Box).to receive(:coach).and_return mock_coach
      allow_any_instance_of(Box).to receive(:push_box_updated_message)
      mock_coach.stub :stop_box
    end

    it "sets banned_at and stops banned user's running boxes" do
      expect(user.banned_at).to be_nil
      Timecop.freeze do
        user.ban!
        expect(user.banned_at).to eq Time.now
      end
      expect(box_2.reload.state).to eq 'stopping'
      expect(box_3.reload.state).to eq 'stopping'
    end

    it "changes user's password to some random string to force trigger session expiry" do
      expect(user.valid_password? '123456').to be_truthy
      user.ban!
      expect(user.valid_password? '123456').to be_falsey
    end

    it 'clears reset password token' do
      expect(user.reset_password_token).to be_present
      expect(user.reset_password_sent_at).to be_present
      user.ban!
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil
    end

    it 'removes all associated n2o_fills' do
      expect(user.n2o_fills.count).to eq 2
      expect(user.max_n2o).not_to eq 0
      user.ban!
      expect(user.reload.n2o_fills.count).to eq 0
      expect(user.max_n2o).to eq 0
    end
  end

  describe '#delinquent!' do
    let!(:user) { create :user, delinquent_at: nil }
    let!(:mock_coach) { instance_double('Coach') }

    let!(:box1) { create :box, owner: user, state: 'running' }
    let!(:box2) { create :box, owner: user, terminated_at: DateTime.now }
    let!(:box3) { create :box, users: [ user ], state: 'running' }
    let!(:box4) { create :box, state: 'running' }

    before do
      allow_any_instance_of(Box).to receive(:coach).and_return mock_coach
      allow_any_instance_of(Box).to receive(:push_box_updated_message)
      mock_coach.stub :stop_box
    end

    it 'sets delinquent_at and stops owned running boxes' do
      Timecop.freeze do
        user.delinquent!
        expect(user.delinquent_at).to eq Time.now
      end

      expect(box1.reload.state).to eql 'stopping'
    end

    it 'pushes delinquent_at updated message' do
      expect(user).to receive(:push_delinquent_at_updated_message)
      user.delinquent!
    end
  end

  describe '#undelinquent!' do
    let!(:user) { create :user }

    context 'when delinquent_at is already set' do
      before { user.update_attribute 'delinquent_at', Time.now }

      it 'sets delinquent_at to nil' do
        user.undelinquent!
        expect(user.reload.delinquent_at).to eq(nil)
      end

      it 'pushes delinquent_at updated message' do
        expect(user).to receive(:push_delinquent_at_updated_message)
        user.undelinquent!
      end
    end

    context 'when delinquent_at is not set' do
      before { user.update_attribute 'delinquent_at', nil }

      it 'does not change delinquent_at' do
        expect {
          user.undelinquent!
        }.not_to change { user.delinquent_at }
      end

      it 'does not push delinquent_at updated message' do
        expect(user).to_not receive(:push_delinquent_at_updated_message)
        user.undelinquent!
      end
    end
  end

  describe '#delinquent?' do
    let!(:user) { create :user }

    it 'returns true if delinquent_at is set' do
      user.delinquent_at = Time.now

      expect(user.delinquent?).to be_truthy
    end

    it 'returns false if delinquent_at is set' do
      user.delinquent_at = nil

      expect(user.delinquent?).to be_falsy
    end
  end

  describe '#reset_password!' do
    let!(:user) { create :user, password: 'foobar', password_confirmation: 'foobar' }

    context 'when banned_at is present' do
      before { user.update_attribute :banned_at, Time.now }

      it 'does not reset password' do
        user.reset_password! '123456', '123456'
        expect(user.valid_password? '123456').to be_falsey
      end
    end

    context 'when banned_at is not present' do
      it 'resets password' do
        user.reset_password! '123456', '123456'
        expect(user.valid_password? '123456').to be_truthy
      end
    end
  end

  describe '#generate_reset_password_token' do
    let!(:user) { create :user }

    context 'when banned_at is present' do
      before { user.update_attribute :banned_at, Time.now }

      it 'does not generate reset password token' do
        user.send :generate_reset_password_token
        expect(user.reset_password_token).to be_nil
        expect(user.reset_password_sent_at).to be_nil
      end
    end

    context 'when banned_at is not present' do
      it 'generates reset password token' do
        user.send :generate_reset_password_token
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_present
      end
    end
  end

  describe '#push_delinquent_at_updated_message' do
    let(:user) { create :user, delinquent_at: Time.now }

    it 'pushes an aio:delinquent_at_updated message to its user' do
      payload = { user: { delinquent_at: user.delinquent_at } }
      expect(Shover).to receive(:publish).with(user.id, 'aio:delinquent_at_updated', payload)
      user.push_delinquent_at_updated_message
    end
  end

  describe "#box_snapshots_allowed?" do
    let!(:user) { create :user }

    it 'is false when user has no plans' do
      expect(user.box_snapshots_allowed).to eq(false)
    end

    context 'when user has plan with no box snapshots feature' do
      let!(:plan) { create :plan }
      before { user.stub(:active_plan).and_return(plan) }

      it 'returns false' do
        expect(plan.features).to be_blank
        expect(user.box_snapshots_allowed).to eq(false)
      end
    end

    context 'when user has plan with box snapshots feature' do
      let!(:plan) { create :plan }
      before { user.stub(:active_plan).and_return(plan) }

      it 'returns true' do
        plan.features = [{'name' => Plan::FEATURE_BOX_SNAPSHOTS, 'live' => true}]
        plan.save!
        expect(user.box_snapshots_allowed).to eq(true)
      end
    end
  end

  describe ".total_count" do
    let!(:user_1) { create :user }
    let!(:user_2) { create :user }
    let!(:user_3) { create :user }

    it "should return the total count of users" do
      expect(User.total_count).to eql('count' => 3)
    end
  end
end
