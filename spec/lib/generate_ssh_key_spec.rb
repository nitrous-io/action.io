require 'spec_helper'

describe GenerateSSHKey do
  it 'generates an proper ssh key' do
    key = double
    expect(SSHKey).to receive(:generate).with(hash_including(type: 'RSA', bits: 2048)) { key }
    expect(described_class.generate).to eq(key)
  end
end
