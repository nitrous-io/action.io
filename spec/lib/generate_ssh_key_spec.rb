require 'spec_helper'

describe GenerateSSHKey do
  it 'generates an proper ssh key' do
    key = stub
    SSHKey.should_receive(:generate).with(hash_including(type: 'RSA', bits: 2048)) { key }
    described_class.generate.should eq(key)
  end
end
