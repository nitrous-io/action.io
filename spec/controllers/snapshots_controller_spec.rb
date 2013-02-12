require 'spec_helper'

describe SnapshotsController do
  let(:user) { create :user }
  let(:box) { create :box }

  describe 'GET index' do
    let!(:snapshots) { [create(:snapshot, owner: user, box: box)] }

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

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let(:params) { { snapshot: { name: 'sample-snapshot', description: "sample snapshot", public: false, box_id: box.to_param  } } }

        it 'creates and persists a snapshot of the given box for the current user' do
          expect {
            do_request(params)
          }.to change { Snapshot.count }.by 1

          snapshot = Snapshot.last
          snapshot.name.should == params[:snapshot][:name]
          snapshot.description.should == params[:snapshot][:description]
          snapshot.public.should == params[:snapshot][:public]
          snapshot.box.should == box 
          snapshot.owner.should == user
        end

        context do
          before { do_request(params) }

          it { should respond_with :created }
          its('response.body') { should == Snapshot.last.serialize_as_json }
        end

        context 'when we disable snapshot creation feature' do
          let!(:allow_snapshot_creation_setting) { ENV['DISABLE_SNAPSHOT_CREATION'] }
          before { ENV['DISABLE_SNAPSHOT_CREATION'] = 'true' }
          after { ENV['DISABLE_SNAPSHOT_CREATION'] = allow_snapshot_creation_setting }

          context 'user is not an admin' do
            it 'does not create a new snapshot' do
              expect {
                do_request(params)
              }.to_not change { Snapshot.count }
            end

            context do
              before { do_request(params) }

              it { should respond_with :unprocessable_entity }
              its('response.body') { should match(/Snapshot creation is temporarily disallowed/) }
            end
          end

          context 'user is an admin' do
            before { user.update_attribute :admin, true }

            it 'creates a new snapshot' do
              expect {
                do_request(params)
              }.to change { Snapshot.count }.by(1)
            end
          end
        end
      end

      context 'with invalid params' do
        context 'with no params' do
          it 'does not create a snapshot object' do
            expect {
              do_request
            }.not_to change { Snapshot.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { assigns(:snapshot).should_not be_persisted }
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

end
