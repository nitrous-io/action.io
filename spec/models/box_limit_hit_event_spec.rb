require 'spec_helper'

describe BoxLimitHitEvent do
  describe "validations" do
    subject { create :box_limit_hit_event }

    it { should validate_presence_of :box_id }
    it { should validate_presence_of :kind   }
    it { should validate_presence_of :limit_hit_at }
    it { should validate_presence_of :logged_event_id }

    it { should validate_uniqueness_of :logged_event_id }
  end

  describe "associations" do
    it { should belong_to :box }
  end

  describe "callbacks" do
    context "after create" do
      let!(:user) { create :user }
      let!(:box)  { create :box, owner: user }

      let!(:box_limit_hit_event) { build :box_limit_hit_event, box_id: box.id, kind: BoxLimitHitEvent::MEMORY }

      before do
        TrackMixpanelEventJob.stub!(:submit_job)
        IncrementMixpanelPropertyJob.stub!(:submit_job)
      end

      it "should track the event as a Mixpanel event" do
        TrackMixpanelEventJob.should_receive(:submit_job).with('Box Memory Limit Hit', user.id,
                                                               { memory: box.memory, storage: box.storage, template: box.box_template.name })
        IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :box_memory_limit_hit_count, 1)

        box_limit_hit_event.save
      end

      it "should update the box's last_hit_memory_limit_at attribute" do
        Timecop.freeze do
          expect(box.last_hit_memory_limit_at).to be_nil
          box_limit_hit_event.save
          expect(box.reload.last_hit_memory_limit_at.to_i).to eql Time.now.to_i
        end
      end
    end
  end
end
