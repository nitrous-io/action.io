require 'spec_helper'

describe ReadDefaultPublicKey do
  let(:ssh) { stub.as_null_object }
  let(:box) { create :box }

  before do
    Net::SSH.stub(:start).and_yield ssh
  end

  it 'reads id_rsa.pub from a box when it is present' do
    Net::SSH.should_receive(:start).with(
      box.host, # host
      "action", # username
      hash_including(port: box.port,
                     key_data: box.key_pairs.first.private_key)).and_yield ssh
    ssh.should_receive(:exec).with("cat /home/action/.ssh/id_rsa.pub").and_yield(stub, :stdout, "public-key")
    ReadDefaultPublicKey.run(box).should eq("public-key")
  end

  it 'returns nothing when there are errors with the command' do
    ssh.should_receive(:exec).with("cat /home/action/.ssh/id_rsa.pub").and_yield(stub, :stderr, "\n")
    ReadDefaultPublicKey.run(box).should be_nil
  end
end
