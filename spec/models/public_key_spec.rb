require 'spec_helper'

describe PublicKey do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :key }
  it { should_not allow_mass_assignment_of :user_id }

  it { should belong_to :user }

  describe 'validations' do
    let(:public_key) { create :public_key }

    it { should validate_presence_of :user }
    it { should validate_presence_of :key }

    it 'validates whether a given key is a valid rsa public key' do
      public_key.key = 'some random string'
      public_key.should_not be_valid
      public_key.key = 'ssh-rsa ABCDEFGHIJKLMNOPQRSTUVWXYZ test@action.io'
      public_key.should_not be_valid
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQC6dOZ1El2Zi7kDtuWr0MOVZKFAJ2zQLlHt3sZ7KnNGAlzoD45lDrbTW/hIDt5vM2g3SztVRpyqB7ZAWSMCeM0yAnx1mycE4xM1Rul7e/9yfmSLmmngOFbDm86SImPimhzQ+mylnoImLgjZFdglcILbQRscFLAXCAtcCsKmisf2Uw== test@action.io'
      public_key.should be_valid
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKcRCibHSPU5OUb0a9cOp+Ou/Hc1dupHfcctUpN55SK3/wXX7SB06cp3jB6E8pIusrHawuhUZ1sINCnes6Ygl+HaqY8xrjQWlUdo7Q0KP97UX85QkMsjMp/x5QmE49P3ArKKy6sUDMIV/eBS6VWFzIkdRBBvFiwxaPi/op8MIK6EzjmcUq0FsTbD2qqGuoVXtPYWcfjMHQ2FL0MBtYz6gVbqAijDsm7o/XV6y4HvMLNYmVJpb9FuGUqyo3/mKSZASE+0blDPuZq6OLUq9BlYSJZLzaggYrNNG1EHeP45Q9sGUQzQj889N6SB23JfA65El0UxisMzeZeYRJzUNTbSh test@action.io'
      public_key.should be_valid
      public_key.key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDwKwu0i0B8QgZPBdIMKIHAuv6kQw/FrDyS9CyrUUOE1qMTPhRjCHrmPpBLbXht08M4uBuyGEz5XxbfIB09NWTxDZFAlTvka3WKJq3eRwfhCaJ47loja0jb4SrMxx90cQ71ExQdrXYCHepYXnmVJn7gS0mssKF0x2Ley5GbyjhIzZ/QjM8LZxcpX0F3JiW+syJcRcVS4RNF9auUU0W0MgoMHiaA2/UwX5KJofPSOOiMOYOcKLutqnAjXs4jPKf+oggABuv2/FWh8ugcZMyqTmXZoaYOiCqQ2AWDVjCKYqYDNW2Msgj0M/LrWMdqVbwa1lTcW6+87Cqqa+by0GDqzi5t test@action.io'
      public_key.should be_valid
    end
  end
end
