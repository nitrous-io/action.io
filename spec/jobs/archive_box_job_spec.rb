require 'spec_helper'

describe ArchiveBoxJob do
  let!(:box)        { create :box }
  let!(:mock_coach) { double('coach') }
  let!(:job)        { described_class.new(box.id) }

  before do
    Box.stub!(:find).with(box.id) { box }
    box.stub!(:coach)             { mock_coach }
  end

  describe '#perform' do
    it 'calles #archive_box on the coach' do
      box.should_receive(:coach).once.ordered.and_return(mock_coach)
      mock_coach.should_receive(:archive_box).once.ordered
      job.perform
    end
  end
end
