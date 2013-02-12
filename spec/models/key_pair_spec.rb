require 'spec_helper'

describe KeyPair do
  it { should belong_to :box }

  it { should_not allow_mass_assignment_of :private_key }
  it { should_not allow_mass_assignment_of :public_key }

  describe 'private key encryption' do
    describe '#private_key=' do
      let(:key_pair) { KeyPair.new }
      let(:key_pair2) { KeyPair.new }

      it 'encrypts private key uniquely' do
        key_pair.encrypted_private_key.should be_blank
        key_pair.encrypted_private_key_iv.should be_blank
        key_pair.private_key = 'some top secret key'
        key_pair.encrypted_private_key.should be_present
        key_pair.encrypted_private_key_iv.should be_present
        key_pair.private_key.should_not == key_pair.encrypted_private_key

        key_pair2.encrypted_private_key.should be_blank
        key_pair2.encrypted_private_key_iv.should be_blank
        key_pair2.private_key = 'some top secret key'
        key_pair2.encrypted_private_key.should be_present
        key_pair2.encrypted_private_key_iv.should be_present
        key_pair2.private_key.should_not == key_pair2.encrypted_private_key

        key_pair.encrypted_private_key.should_not == key_pair2.encrypted_private_key
        key_pair.encrypted_private_key_iv.should_not == key_pair2.encrypted_private_key_iv
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
        kp.private_key.should == 'super proprietary and confidential key'
      end
    end
  end
end

# == Schema Information
#
# Table name: key_pairs
#
#  id                       :integer          not null, primary key
#  box_id                   :integer          not null
#  public_key               :text             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  encrypted_private_key    :text             not null
#  encrypted_private_key_iv :string(255)      not null
#
