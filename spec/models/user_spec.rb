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
  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:boxes).through(:box_admins) }
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

    describe 'invite code' do
      let!(:user) { build(:user, email: 'i@mclov.in', invite_code: 'deadbeef') }

      it "rejects blank value" do
        user.invite_code = nil
        expect(user).to_not be_valid
      end

      it "is valid for all codes that user receives" do
        user.invite_code = 'livebeef'
        expect(user).to_not be_valid

        create :invite, email: 'i@mclov.in', inviting_user_id: 9999, invite_code: 'livebeef'
        user.invite_code = 'livebeef'
        expect(user).to be_valid

        create :invite, email: 'imnot@clov.in', inviting_user_id: 9999, invite_code: 'sadbeef'
        user.invite_code = 'sadbeef'
        expect(user).to_not be_valid
      end
    end
  end

  describe 'callbacks' do
    let(:user)  { build :user }

    it 'should set the authentication token' do
      user.save
      user.reload.authentication_token.should be_present
    end

    it 'sets all invites associated with the user to be accepted' do
      another_invite = create :invite, email: user.email, inviting_user_id: 9999
      user.save
      states = Invite.where(email: user.email).pluck(:state).uniq
      expect(states).to eq(['accepted'])
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

  describe "#functional_boxes" do
    it 'does not include boxes which was terminated more than 1 day ago' do
      user = create :user
      box1 = create :box, owner: user
      box2 = create :box, owner: user, terminated_at: 30.minutes.ago
      box3 = create :box, owner: user, terminated_at: 2.days.ago

      user.functional_boxes.should =~ [box1, box2]
    end
  end

  describe "#able_to_invite?" do
    it "is true when user has available invite" do
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

  describe "#owned_invite_with_email" do
    it 'returns owned invite that has specified email' do
      user = create :user
      invite = create :invite, email: "test@email.com", inviting_user: user
      user.owned_invite_with_email("test@email.com").should eq(invite)
      user.owned_invite_with_email("not@there.com").should be_nil
    end
  end

  # TODO
  # describe "#create_snapshot"
  # describe "#create_box"
end

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  username               :string(255)      not null
#  encrypted_password     :string(255)
#  email                  :string(255)      not null
#  full_name              :string(255)
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  authentication_token   :string(255)
#  invite_code            :string(255)
#  admin                  :boolean          default(FALSE), not null
#  available_invites      :integer          default(0), not null
#

