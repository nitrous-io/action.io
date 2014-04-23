require 'spec_helper'

describe BoxTransition do
  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :event }
  it { should_not allow_mass_assignment_of :from_state }
  it { should_not allow_mass_assignment_of :to_state }
  it { should_not allow_mass_assignment_of :triggered_by }

  it { should belong_to(:user) }
  it { should belong_to(:box) }

  describe 'validations' do
    it { should validate_presence_of(:box) }
    it { should validate_presence_of(:event) }
    it { should validate_presence_of(:from_state) }
    it { should validate_presence_of(:to_state) }
    it { should validate_presence_of(:triggered_by) }

    it { should allow_value('admin').for(:triggered_by) }
    it { should_not allow_value('some admin').for(:triggered_by) }

    describe 'triggered_by user requires user_id' do
      let(:user) { build :user }
      let(:box_transition) { BoxTransition.new }

      it 'requires user if triggered_by is "user"' do
        box_transition.triggered_by = 'user'
        expect(box_transition.error_on(:user)).to include(match(/triggered_by is user/))
        box_transition.user = user
        expect(box_transition.error_on(:user)).to be_empty
      end
    end
  end

  describe 'callbacks' do
    describe '#maybe_emit_to_datadog' do
      def expect_datadog_emit(expected_metric, expected_duration)
        expect(DatadogEmitPointJob).to receive(:submit_job) do |metric, duration, options|
          expect(metric).to eq expected_metric
          expect(duration.floor).to eq expected_duration
        end
      end

      let!(:box) { create :box }
      let!(:mock_coach) do
        instance_double('Coach', provision_box: nil, start_box: nil,
                        restart_box: nil, stop_box: nil, terminate_box: nil)
      end

      before do
        box.stub(:coach) { mock_coach }
        box.stub(:push_box_updated_message)
      end

      it 'does not emit or warn on initial provision event' do
        expect(DatadogEmitPointJob).not_to receive(:submit_job)
        expect(Rails.logger).not_to receive(:warn).with(/Mismatched events/)
        box.enqueue_provision!
      end

      it 'emits box provisioning time' do
        expect_datadog_emit('nitrous_io.box_provision.timing', 60)

        Timecop.freeze(2.minutes.ago) { box.enqueue_provision! }
        Timecop.freeze(1.minutes.ago) { box.enqueue_start! }
      end

      describe 'emits box starting time' do
        before do
          box.update_column(:state, 'provisioning')
          expect_datadog_emit('nitrous_io.box_start.timing', 60)
        end

        it 'on repo clone' do
          Timecop.freeze(2.minutes.ago) { box.enqueue_start! }
          Timecop.freeze(1.minutes.ago) { box.enqueue_clone_repo! }
        end

        it 'on regular box start' do
          Timecop.freeze(2.minutes.ago) { box.enqueue_start! }
          Timecop.freeze(1.minutes.ago) { box.start! }
        end
      end

      it 'emits box restart time' do
        box.update_column(:state, 'running')
        expect_datadog_emit('nitrous_io.box_restart.timing', 30)
        Timecop.freeze(2.minutes.ago) { box.enqueue_restart! }
        Timecop.freeze(90.seconds.ago) { box.restart! }
      end

      it 'emits box stop time' do
        box.update_column(:state, 'running')
        expect_datadog_emit('nitrous_io.box_stop.timing', 1)
        start_time = 5.seconds.ago
        Timecop.freeze(start_time) { box.enqueue_stop! }
        Timecop.freeze(start_time + 1) { box.stop! }
      end

      it 'emits box terminate time' do
        box.update_column(:state, 'stopped')
        expect_datadog_emit('nitrous_io.box_terminate.timing', 30)
        Timecop.freeze(2.minutes.ago) { box.enqueue_terminate! }
        Timecop.freeze(90.seconds.ago) { box.terminate! }
      end

      it 'emits box snapshot time' do
        box.update_column(:state, 'stopped')
        expect_datadog_emit('nitrous_io.box_snapshot.timing', 30)
        Timecop.freeze(2.minutes.ago) { box.enqueue_snapshot! }
        Timecop.freeze(90.seconds.ago) { box.snapshot! }
      end

      it 'emits box clone time' do
        box.update_column(:state, 'running')

        expect_datadog_emit('nitrous_io.box_clone.timing', 30)
        Timecop.freeze(2.minutes.ago) { box.enqueue_clone_repo! }
        Timecop.freeze(90.seconds.ago) { box.complete_clone_repo! }
      end

      it 'emits box parameters as options' do
        expect(DatadogEmitPointJob).to receive(:submit_job) do |metric, duration, options|
          expect(options[:tags]).to eq ['test', "region:#{box.region.name}"]
          expect(options[:host]).to eq box.host
          expect(options[:stack]).to eq box.box_template.name
        end
        Timecop.freeze(2.minutes.ago) { box.enqueue_provision! }
        Timecop.freeze(1.minutes.ago) { box.enqueue_start! }
      end

      it 'does not emit and warns on mismatched events' do
        expect(DatadogEmitPointJob).not_to receive(:submit_job)
        expect(Rails.logger).to receive(:warn).with(/Mismatched events/)
        fake_transition = box.box_transitions.build.tap do |bt|
          bt.event = 'complete_clone_repo'
          bt.from_state = 'cloning_repo'
          bt.to_state = 'running'
          bt.triggered_by = 'admin'
        end
        fake_transition.save!
      end
    end
  end

  describe 'defaults' do
    it 'triggered_by to unknown' do
      expect(BoxTransition.new.triggered_by).to eql('unknown')
    end
  end
end
