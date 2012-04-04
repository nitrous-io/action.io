require 'spec_helper'

describe User do
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :email }
  it { should allow_mass_assignment_of :full_name }
  it { should allow_mass_assignment_of :password }
  it { should allow_mass_assignment_of :password_confirmation }
  it { should allow_mass_assignment_of :remember_me }

  it { should_not allow_mass_assignment_of :encrypted_password }
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

  describe 'validations' do
    before { create(:user).should be_valid }

    it { should validate_presence_of :username }
    it { should validate_presence_of :email }
    it { should validate_presence_of :full_name }

    it { should validate_uniqueness_of :username }
    it { should validate_uniqueness_of :email }

    it { should ensure_length_of(:username).is_at_least(4).is_at_most(20) }
    it { should ensure_length_of(:full_name).is_at_least(1).is_at_most(40) }
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
end
