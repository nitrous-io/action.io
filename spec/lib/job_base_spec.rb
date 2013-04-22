require 'spec_helper'

describe JobBase do
  class DummyJob < JobBase
    attr_accessor :id
    def initialize(id); self.id = id; end
    def perform; end
  end
  let(:test_job_klass) { DummyJob }

  def submit_job(attrs)
    test_job_klass.submit test_job_klass.new(attrs)
  end

  def locked_job
    Delayed::Job.reserve Delayed::Worker.new
  end

  before { Delayed::Job.delete_all }

  describe '#submit' do
    it 'enqueues a new delayed job' do
      expect { submit_job 10 }.to change { Delayed::Job.count }.by 1
      last_job = Delayed::Job.last.payload_object
      last_job.id.should eq(10)
    end

    context 'when we want an unique job' do
      let(:test_job_klass) do
        Class.new(DummyJob) do
          unique true
        end
      end

      it 'does not allows duplicate' do
        submit_job 10
        expect { submit_job 10 }.to_not change { Delayed::Job.count }
      end

      it 'allows one running job and one in the queue' do
        submit_job 10
        locked_job

        expect {
          submit_job 10
          submit_job 10
        }.to change { Delayed::Job.count }.by 1
      end
    end
  end
end
