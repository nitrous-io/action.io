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
    before { create(:authentication).should be_valid }

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
      authentication.provider.should == 'facebook'
      authentication.uid.should == '123456'
      authentication.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
    end
  end
end

# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string(255)      not null
#  uid        :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  token      :string(255)
#
