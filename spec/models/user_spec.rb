require 'spec_helper'

describe User do
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :email }
  it { should allow_mass_assignment_of :full_name }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :password_confirmation }
  it { should allow_mass_assignment_of :remember_me }

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
  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:boxes).through(:box_admins) }
  it { should have_many(:owned_boxes).class_name('Box').dependent(:nullify) }
  it { should have_many(:public_keys).dependent(:destroy) }

  describe 'validations' do
    let!(:user) { create :user }

    it { should validate_presence_of :username }
    it { should validate_presence_of :email }
    it { should validate_presence_of :full_name }

    it { should validate_uniqueness_of :username }
    it { should validate_uniqueness_of :email }

    it { should ensure_length_of(:username).is_at_least(4).is_at_most(20) }
    it { should ensure_length_of(:full_name).is_at_least(1).is_at_most(40) }
  end

  describe 'callbacks' do
    let(:user)  { build :user }

    it 'should set the authentication token' do
      user.save
      user.reload.authentication_token.should be_present
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

  describe '#apply_omniauth_hash' do
    let(:hash) do
      {
        'provider' => 'facebook',
        'uid' => '123456',
        'info' => {
          'email' => 'test@example.com',
          'name'  => 'John Doe',
          'nickname' => 'johndoe'
        },
        'credentials' => {
          'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        }
      }
    end

    it 'creates an authentication and sets attributes with the data in a given hash' do
      user = User.new
      user.apply_omniauth_hash(hash)
      user.username.should == 'johndoe'
      user.email.should == 'test@example.com'
      user.full_name.should == 'John Doe'
      user.authentications.should have(1).authentication
      authentication = user.authentications.first
      authentication.provider.should == 'facebook'
      authentication.uid.should == '123456'
      authentication.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
    end

    context 'when there are some existing attributes' do
      it 'does not overwrite them' do
        user = User.new username: 'petekim', email: 'pete@example.com', full_name: 'Pete Kim'
        user.apply_omniauth_hash(hash)
        user.username.should == 'petekim'
        user.email.should == 'pete@example.com'
        user.full_name.should == 'Pete Kim'
      end
    end

    it 'does not cause an error when a given hash is empty' do
      expect {
        user = User.new
        user.apply_omniauth_hash
      }.not_to raise_error
    end
  end

  describe '#new_with_session' do
    let(:params) { { email: 'test@example.com' } }

    context 'when session contains devise.omniauth_hash' do
      let(:session) do
        {
          'devise.omniauth_hash' => {
            'provider' => 'github',
            'uid' => '123456',
            'info' => {
              'name'  => 'John Doe',
              'nickname' => 'johndoe'
            },
            'credentials' => {
              'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
            }
          }
        }
      end

      it 'creates a new user with the omniauth hash and given params' do
        user = User.new_with_session(params, session)
        user.username.should == 'johndoe'
        user.email.should == 'test@example.com'
        user.full_name.should == 'John Doe'
        user.authentications.should have(1).authentication
        authentication = user.authentications.first
        authentication.provider.should == 'github'
        authentication.uid.should == '123456'
        authentication.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
      end
    end

    context 'when session does not contain devise.omniauth.hash' do
      it 'just creates a new user with given params' do
        user = User.new_with_session(params, {})
        user.username.should be_nil
        user.email.should == 'test@example.com'
        user.full_name.should be_nil
        user.authentications.should be_empty
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

  describe 'JSON representation' do
    let!(:user) do
      create :user,
        reset_password_token: 'token',
        reset_password_sent_at: Time.now,
        remember_created_at: Time.now,
        sign_in_count: 10,
        current_sign_in_at: Time.now,
        last_sign_in_at: Time.now,
        current_sign_in_ip: '127.0.0.1',
        last_sign_in_ip: '127.0.0.1'
    end

    let!(:authentication) { create :authentication, user: user }
    let(:json_hash) { user.as_json }

    it 'excludes sensitive fields' do
      json_hash.should_not include :encrypted_password
      json_hash.should_not include :reset_password_token
      json_hash.should_not include :reset_password_sent_at
      json_hash.should_not include :remember_created_at
      json_hash.should_not include :sign_in_count
      json_hash.should_not include :current_sign_in_at
      json_hash.should_not include :last_sign_in_at
      json_hash.should_not include :current_sign_in_ip
      json_hash.should_not include :last_sign_in_ip
    end

    it 'includes authentications as a sub hash' do
      json_hash['authentications'].should have(1).item
      json_hash['authentications'].first.should == authentication.as_json
    end
  end
end
