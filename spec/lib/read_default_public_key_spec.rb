require 'spec_helper'

describe ReadDefaultPublicKey do
  let(:ssh) { double.as_null_object }
  let(:box) { create :box }

  before do
    Net::SSH.stub(:start).and_yield ssh
  end

  it 'reads id_rsa.pub from a box when it is present' do
    expect(Net::SSH).to receive(:start).with(
      box.host, # host
      "action", # username
      hash_including(port: box.port,
                     key_data: box.key_pairs.first.private_key)).and_yield ssh
    expect(ssh).to receive(:exec).with("cat /home/action/.ssh/id_rsa.pub").and_yield(double, :stdout, "public-key")
    expect(ReadDefaultPublicKey.run(box)).to eq("public-key")
  end

  it 'strips whitespace from the key' do
    expect(ssh).to receive(:exec).with("cat /home/action/.ssh/id_rsa.pub").and_yield(double, :stdout, "public-key\n")
    expect(ReadDefaultPublicKey.run(box)).to eq("public-key")
  end

  it 'returns nothing when there are errors with the command' do
    expect(ssh).to receive(:exec).with("cat /home/action/.ssh/id_rsa.pub").and_yield(double, :stderr, "\n")
    expect(ReadDefaultPublicKey.run(box)).to be_nil
  end
end
