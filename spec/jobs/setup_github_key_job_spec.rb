require 'spec_helper'

describe SetupGithubKeyJob do
  describe '#perform' do
    let!(:box)        { Box.new }
    let!(:job)        { described_class.new(box.id) }

    before do
      Box.stub(:find).with(box.id) { box }
    end

    it 'calls provision_box method on the coach' do
      expect(SetupGithubKey).to receive(:setup).with(box).once
      job.perform
    end
  end
end
