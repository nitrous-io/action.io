require 'spec_helper'

describe Authentication do
  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :provider }
  it { should_not allow_mass_assignment_of :uid }
  it { should_not allow_mass_assignment_of :token }
  it { should_not allow_mass_assignment_of :created_at }
  it { should_not allow_mass_assignment_of :updated_at }

  it { should belong_to :user }

  describe 'validations' do
    before { expect(create(:authentication)).to be_valid }

    it { should validate_presence_of :provider }
    it { should validate_presence_of :uid }
  end

  describe '#apply_omniauth_hash' do
    let(:hash) do
      {
        'provider' => 'facebook',
        'uid' => '123456',
        'credentials' => {
          'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        }
      }
    end

    it 'sets attributes with the the data in a given ominauth hash' do
      authentication = Authentication.new
      authentication.apply_omniauth_hash(hash)
      expect(authentication.provider).to eq('facebook')
      expect(authentication.uid).to eq('123456')
      expect(authentication.token).to eq('b27e7786caf89a6373a3799fa9a57e4558dc2363')
      expect(authentication.meta).to eq(hash.to_json)
    end

    it 'stores username if found' do
      authentication = Authentication.new
      authentication.apply_omniauth_hash(hash)
      expect(authentication.username).not_to be_present

      hash['info'] = { 'nickname' => "hello" }
      authentication.apply_omniauth_hash(hash)
      expect(authentication.username).to eq("hello")
    end
  end
end
