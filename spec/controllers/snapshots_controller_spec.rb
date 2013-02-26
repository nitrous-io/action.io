require 'spec_helper'

describe SnapshotsController do
  let(:user) { create :user }
  let(:box) { create :box, owner: user }

  describe 'GET index' do
    let!(:snapshots) { [create(:snapshot, box: box)] }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        controller.current_user.stub(:snapshots) { snapshots }
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's snapshots as json" do
        assigns(:snapshots).should eq(snapshots)
        response.body.should eq({ snapshots: snapshots.serialize_as_hash }.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'POST create' do
    def do_request(params={ snapshot: {} })
      post :create, { format: 'json' }.merge(params)
    end

    before do
      Snapshot.any_instance.stub(:push_snapshot_updated_message)
      Box.any_instance.stub(:push_box_updated_message)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let(:params) { { snapshot: { name: 'sample-snapshot', description: "sample snapshot", public: false, box_id: box.to_param  } } }
        before do
          box.update_attribute :state, :running
        end

        it 'creates and persists a snapshot of the given box for the current user' do
          do_request(params)
          snapshot = assigns(:snapshot)
          snapshot.should be_persisted
          snapshot.name.should eq(params[:snapshot][:name])
          snapshot.description.should eq(params[:snapshot][:description])
          snapshot.public.should eq(params[:snapshot][:public])
          snapshot.box.should eq(box)
          snapshot.owner.should eq(user)
        end

        context do
          before { do_request(params) }
          it { should respond_with :created }
        end
      end

      context 'with invalid params' do
        it 'fails when box is invalid' do
          expect { do_request }.to raise_error(ActiveRecord::RecordNotFound)
        end

        context 'when snapshot cannot be saved' do
          before do
            params = {
              snapshot: {
                description: "sample snapshot",
                box_id: box.to_param
              }
            }
            do_request params
          end
          it { should respond_with :unprocessable_entity }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let!(:snapshot1) { create :snapshot, box: create(:box) }
    let!(:snapshot2) { create :snapshot, box: create(:box) }
    let!(:user) { snapshot1.owner }

    def do_request(params={ id: '1' })
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          before { do_request id: snapshot1.to_param }

          it { should respond_with :success }
          its('response.body') { should == snapshot1.serialize_as_json }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: snapshot2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE destroy' do
    let!(:snapshot1) { create :snapshot }
    let!(:snapshot2) { create :snapshot }
    let!(:user) { snapshot1.owner }

    def do_request(params={ id: '1' })
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'when a valid id is given' do
        context 'when the snapshot belongs to the current user' do
          let(:params) { { id: snapshot1.to_param } }

          it 'deletes the public key object' do
            expect {
              do_request(params)
            }.to change { Snapshot.count }.by(-1)

            expect {
              snapshot1.reload
            }.to raise_error ActiveRecord::RecordNotFound
          end

          context do
            before { do_request params }
            it { should respond_with :no_content }
          end
        end

        context 'when the public key belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: snapshot2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT restore' do
    let!(:box) { create :box }
    let!(:snapshot1) { create :snapshot, box: box }
    let!(:snapshot2) { create :snapshot }
    let!(:user) { snapshot1.owner }

    def do_request(params={id: '1'})
      put :restore, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
        Coach.any_instance.stub(:restore_snapshot)
      end

      context 'when a valid id is given' do
        context 'when the snapshot belongs to the current user' do
          let(:params) { { id: snapshot1.to_param, box_id: box.id } }

          it 'create a delayed job to restore the snapshot' do
            expect {
              do_request params
            }.to change { Delayed::Job.count }.by 1
            job = Delayed::Job.last.payload_object
            job.should be_kind_of(RestoreSnapshotJob)
            job.box_id.should eq(box.id)
            job.snapshot_id.should eq(snapshot1.id)
          end

          context do
            before { do_request params }
            it { should respond_with :success }
          end
        end

        context 'when snapshots belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: snapshot2.to_param, box_id: box.id
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        context 'when box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: snapshot1.to_param, box_id: snapshot2.box.id
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id', box_id: box.id
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
