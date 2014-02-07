require 'spec_helper'

describe SnapshotsController do
  let(:user) { create :user }
  let(:box) { create :box, owner: user }

  describe 'GET index' do
    def do_request(params={})
      get :index, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      let!(:another_box) { create :box, owner: user }
      let!(:another_user) { create :user }
      let!(:another_users_box) { create :box, owner: another_user }
      let(:snapshot1) { create :snapshot, box: box, user: user, created_at: 2.days.ago }
      let(:snapshot2) { create :snapshot, box: box, user: user, created_at: 1.day.ago }
      let(:snapshot3) { create :snapshot, box: another_box, user: user, created_at: 3.days.ago }
      let(:snapshot4) { create :snapshot, box: another_users_box, user: another_user, created_at: 1.day.ago }

      before do
        sign_in user
        Timecop.freeze
        snapshot1; snapshot2; snapshot3; snapshot4
      end

      after { Timecop.return }

      context 'when listing snapshots of a box' do
        before { do_request box_id: box.to_param }

        it "returns the current user's snapshots of the box reverse sorted by creation time" do
          expect(assigns(:snapshots).to_a).to eql([snapshot2, snapshot1])
          expect(response.body).to eq({ snapshots: assigns(:snapshots).serialize_as_hash }.to_json)
        end

        it { should respond_with :success }
      end

      context 'when listing all snapshots' do
        before { do_request }

        it "returns all the current user's snapshots reverse sorted by creation time" do
          expect(assigns(:snapshots).to_a).to eql([snapshot2, snapshot1, snapshot3])
          expect(response.body).to eq({ snapshots: assigns(:snapshots).serialize_as_hash }.to_json)
        end

        it { should respond_with :success }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

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
