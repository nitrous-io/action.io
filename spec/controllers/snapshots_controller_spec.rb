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

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let(:params) { { snapshot: { name: 'sample-snapshot', description: "sample snapshot", public: false, box_id: box.to_param  } } }

        before do
          Coach.any_instance.should_receive(:snapshot_box)
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
end
