require 'spec_helper'

describe DatadogEmitPointJob do
  let(:metric)    { 'metric' }
  let(:value)     { 'value'  }
  let(:options)   { { tags: 'test' } }

  describe '#perform' do
    before do
      Datadog.stub(:emit_point).and_return(true)
    end

    it "should send metrics to Datadog" do
      expect(Datadog).to receive(:emit_point).with(metric, value, options)
      DatadogEmitPointJob.new(metric, value, options).perform
    end
  end

  describe ".submit_job" do
    it "should submit a delayed job" do
      expect {
        DatadogEmitPointJob.submit_job(metric, value, options)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/DatadogEmitPointJob.*?metric: metric/m)
      expect(job_handler).to match(/DatadogEmitPointJob.*?value: value/m)
      expect(job_handler).to match(/DatadogEmitPointJob.*?options:.*?:tags: test/m)
    end
  end
end

