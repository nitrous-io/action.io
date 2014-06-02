require 'spec_helper'

describe BoxhostKeyPair do
  it { should belong_to :boxhost }

  it { should_not allow_mass_assignment_of :public_key }
  it { should_not allow_mass_assignment_of :encrypted_private_key }
  it { should_not allow_mass_assignment_of :encrypted_private_key_iv }

  describe 'private key encryption' do
    describe '#private_key=' do
      let(:key_pair) { KeyPair.new }
      let(:key_pair2) { KeyPair.new }

      it 'encrypts private key uniquely' do
        expect(key_pair.encrypted_private_key).to be_blank
        expect(key_pair.encrypted_private_key_iv).to be_blank
        key_pair.private_key = 'some top secret key'
        expect(key_pair.encrypted_private_key).to be_present
        expect(key_pair.encrypted_private_key_iv).to be_present
        expect(key_pair.private_key).not_to eq(key_pair.encrypted_private_key)

        expect(key_pair2.encrypted_private_key).to be_blank
        expect(key_pair2.encrypted_private_key_iv).to be_blank
        key_pair2.private_key = 'some top secret key'
        expect(key_pair2.encrypted_private_key).to be_present
        expect(key_pair2.encrypted_private_key_iv).to be_present
        expect(key_pair2.private_key).not_to eq(key_pair2.encrypted_private_key)

        expect(key_pair.encrypted_private_key).not_to eq(key_pair2.encrypted_private_key)
        expect(key_pair.encrypted_private_key_iv).not_to eq(key_pair2.encrypted_private_key_iv)
      end
    end

    describe '#private_key' do
      let!(:key_pair) { build :key_pair }

      before do
        key_pair.private_key = 'super proprietary and confidential key'
        key_pair.save!
      end

      it 'decrypts encrypted private key' do
        kp = KeyPair.find(key_pair.id)
        expect(kp.private_key).to eq('super proprietary and confidential key')
      end
    end
  end
end
