require 'spec_helper'

describe SnapshotsController do
  let(:user) { create :user }
  let(:box) { create :box, owner: user }

  describe 'POST create' do
    def do_request(params={})
      post :create, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        let(:params) { { snapshot: { name: 'snapshot-1', box_id: box.to_param, public: false } } }

        before do
          box.update_attribute :state, 'stopped'
          allow_any_instance_of(Box).to receive(:push_box_updated_message)
          allow(TrackMixpanelEventJob).to receive(:submit_job).with('Box Snapshot Taken', user.id)
          allow(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :boxes_snapshotted, 1)
        end

        it 'creates and assigns a snapshot' do
          expect {
            do_request params
          }.to change { box.snapshots.count }.by 1
          snapshot = assigns(:snapshot)
          expect(snapshot).to eql Snapshot.last
          expect(snapshot).to be_persisted
          expect(snapshot.name).to eql params[:snapshot][:name]
          expect(snapshot.public).to eql params[:snapshot][:public]
          expect(snapshot.box).to eql box
          expect(snapshot.user).to eql user
        end

        it 'tracks the appropriate Mixpanel event and property' do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Snapshot Taken', user.id)
          expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :boxes_snapshotted, 1)
          do_request params
        end

        context do
          before { do_request params }

          it { should respond_with :created }
          its('response.body') { should == Snapshot.last.serialize_as_json }
        end
      end

      context 'when box_id is not present' do
        it 'should raise an ActiveRecord::RecordNotFound error' do
          expect {
            do_request snapshot: { name: 'snapshot-1' }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with invalid params' do
        let(:params) { { snapshot: { box_id: box.to_param } } }

        it 'should not create a snapshot' do
          expect {
            do_request params
          }.not_to change { box.snapshots.count }
        end
      end

      context 'when box is not stopped' do
        before { box.update_attribute :state, 'running' }

        it 'should not create a snapshot' do
          expect {
            do_request snapshot: { name: 'snapshot-1', box_id: box.to_param }
          }.not_to change { box.snapshots.count }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
