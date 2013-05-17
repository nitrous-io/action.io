require 'spec_helper'

describe User do
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :email }
  it { should allow_mass_assignment_of :full_name }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :password_confirmation }
  it { should allow_mass_assignment_of :remember_me }
  it { should allow_mass_assignment_of :invite_code }

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
  it { should_not allow_mass_assignment_of :available_invites }

  it { should have_many(:authentications).dependent(:destroy) }
  it { should have_many(:box_users).dependent(:destroy) }
  it { should have_many(:boxes).through(:box_users) }
  it { should have_many(:owned_boxes).class_name('Box').dependent(:nullify) }
  it { should have_many(:public_keys).dependent(:destroy) }
  it { should have_many(:oauth_applications).dependent(:destroy) }
  it { should have_many(:owned_invites).class_name('Invite').dependent(:nullify) }

  describe 'validations' do
    let!(:user) { create :user }

    it { should validate_presence_of :username }
    it { should validate_presence_of :email }

    it { should validate_uniqueness_of :username }
    it { should validate_uniqueness_of :email }

    it { should ensure_length_of(:username).is_at_least(4).is_at_most(20) }
    it { should ensure_length_of(:full_name).is_at_least(0).is_at_most(40) }

    it { should allow_value(nil).for(:full_name) }
  end

  describe 'callbacks' do
    let(:user)  { build :user }

    it 'should set the authentication token' do
      user.save
      user.reload.authentication_token.should be_present
    end
  end

  describe '#activated?' do
    it 'is true when user as an activated invite' do
      user = create :user
      user.should_not be_activated

      invite = Invite.find_by_email(user.email)
      invite.update_attribute :state, "accepted"
      user.should be_activated
    end
  end

  describe '#request_invite' do
    let!(:user) { create :user, email: "i@mclov.in" }
    before { user.received_invitations.destroy_all }

    it 'creates a new invite for the user' do
      expect {
        user.request_invite("202.157.130.10")
      }.to change { user.received_invitations.count }.by 1
      invite = user.received_invitations.last
      invite.email.should == 'i@mclov.in'
      invite.ip.should == '202.157.130.10'
    end

    it "should send an email to the user with the invite confirmation and geocode the invite" do
      invite = user.request_invite

      Delayed::Job.all[0].handler.should =~ /GeocodeInviteJob\ninvite_id: #{invite.id}/
    end

    context 'when enable AUTO_INVITE env variables' do
      let!(:auto_invite_setting) { ENV['AUTO_INVITE'] }
      before { ENV['AUTO_INVITE'] = 'true' }
      after { ENV['AUTO_INVITE'] = auto_invite_setting }

      it 'activates the invite' do
        invite = user.request_invite
        invite.should be_activated
      end

      it 'sends invitation email to user' do
        invite = user.request_invite
        Delayed::Job.all[-1].handler.should =~ /send_invite\nargs:\n- #{invite.id}/
      end
    end

    context "when an invite with that email address already exists" do
      before { create(:invite, :email => user.email) }

      it "should not create a new invite" do
        expect {
          user.request_invite
        }.to change(Invite, :count).by(0)
      end
    end
  end

  describe '#password_required?' do
    let(:user) { create :user }

    context 'when it does not have any authentication object' do
      it 'returns true' do
        user.password_required?.should be_true
      end
    end

    context 'when it has an authentication object' do
      let!(:authentication) { create :authentication, user: user }

      context 'when adding a password' do
        it 'returns true' do
          user.password_required?.should be_true
        end
      end

      context 'when not adding a password' do
        it 'returns false' do
          user.password = ''
          user.password_required?.should be_false
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
      box3 = create :box, owner: user, terminated_at: 2.days.ago

      user.visible_boxes.should =~ [box1, box2]
    end
  end

  describe '#able_to_invite?' do
    it 'is true when user has available invite' do
      user = User.new
      user.available_invites = 1
      user.should be_able_to_invite
    end

    it "is false when user does not have availalbe invite" do
      user = User.new
      user.available_invites = 0
      user.should_not be_able_to_invite
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

  describe '#create_box' do
    let!(:rails_box_template) { create :box_template, runtime: 'rails', enabled: true }
    let!(:region) { create :region, enabled: true }
    let!(:box_attr) {
      {
        name: "fragrant-wind-69",
        box_template_id: rails_box_template.to_param,
        region_id: region.to_param
      }
    }

    context "when user is activated" do
      it "creates a box" do
        user = create :user
        user.stub(:activated?) { true }
        box = user.create_box box_attr
        box.should be_valid
        box.should be_persisted
      end
    end

    context "when user is not activated" do
      it "does not create a box" do
        user = create :user
        user.stub(:activated?) { false }
        box = user.create_box box_attr
        box.should_not be_valid
      end
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
end
