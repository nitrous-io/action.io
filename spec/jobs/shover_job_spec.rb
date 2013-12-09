require 'spec_helper'

describe ShoverJob do
  describe '#perform' do
    context 'when user_id is present' do
      it 'does post_publish' do
        expect(Shover).to receive(:post_publish).with(123, 'foo', { bar: 123 }, 138602200).once
        ShoverJob.new(123, 'foo', { bar: 123 }, 138602200).perform
      end
    end

    context 'when user_id is nil' do
      it 'does post_broadcast' do
        expect(Shover).to receive(:post_broadcast).with('lol', { baz: 'qux' }, 138603300).once
        ShoverJob.new(nil, 'lol', { baz: 'qux' }, 138603300).perform
      end
    end
  end

  describe ".submit_job" do
    it 'submits a delayed job' do
      expect {
        ShoverJob.submit_job(123, 'foo', { bar: 123 }, 138600123)
      }.to change(Delayed::Job, :count).by(1)

      job = YAML.load(Delayed::Job.last.handler)
      expect(job).to be_a ShoverJob
      expect(job.user_id).to eq 123
      expect(job.event).to eq 'foo'
      expect(job.data).to eq({ bar: 123 })
      expect(job.timestamp).to eq 138600123
    end
  end
end
