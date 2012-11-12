require 'spec_helper'

describe SetupGithubKeyJob do
  describe '#perform' do
    let!(:box)        { Box.new }
    let!(:mock_coach) { double('coach') }
    let!(:job)        { described_class.new(box.id) }

    before do
      Box.stub!(:find).with(box.id) { box }
      box.stub!(:coach)             { mock_coach }
    end

    it 'calls provision_box method on the coach' do
      ssh_key = stub
      GenerateSSHKey.should_receive(:generate) { ssh_key }
      SetupGithubKey.should_receive(:setup).with(box, ssh_key).once
      job.perform
    end
  end
end
