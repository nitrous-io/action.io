require 'spec_helper'

describe BoxesController do
  let(:user) { create :user }

  describe 'GET index' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, users: [user] }
    let!(:box2) { create :box, users: [user, another_user] }
    let!(:box3) { create :box, users: [another_user] }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's boxes" do
        response.body.should == [box1, box2].to_json
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'POST create' do
    def do_request(params={})
      post :create, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let(:template) { create :template }
        let(:params) { { name: 'fragrant-wind-69', region: 'us-east-1', template_id: template.to_param } }

        it 'creates and persists a box object for the current user' do
          expect {
            do_request(params)
          }.to change { Box.count }.by 1

          box = Box.last
          box.name.should == params[:name]
          box.region.should == params[:region]
          box.template.should == template
          box.users.should == [user]
        end

        context do
          before { do_request(params) }

          it { should respond_with :created }
          its('response.body') { should == Box.last.to_json }
        end
      end

      context 'with invalid params' do
        it 'does not create a box object' do
          expect {
            do_request
          }.not_to change { Box.count }.by 1
        end

        context do
          before { do_request }

          it { should respond_with :unprocessable_entity }
          it { assigns(:box).should_not be_persisted }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, users: [user] }
    let!(:box2) { create :box, users: [another_user] }

    def do_request(params={})
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          before { do_request id: box1.to_param }

          it { should respond_with :success }
          its('response.body') { should == box1.to_json }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
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

  describe 'PUT update' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, users: [user], name: 'twilight-waterfall-42', region: 'us-east-1' }
    let!(:box2) { create :box, users: [another_user] }

    def do_request(params={})
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'with valid params' do
          let(:params) { { name: 'fragrant-wind-69', region: 'ap-southeast-1' } }

          context 'when the box belongs to the current user' do
            before { do_request params.merge(id: box1.to_param) }

            it 'updates the box object' do
              box1.reload
              box1.name.should == params[:name]
              box1.region.should == params[:region]
            end

            it { should respond_with :no_content }
          end

          context 'when the box belongs to another user' do
            it 'raises record not found' do
              expect {
                do_request params.merge(id: box2.to_param)
              }.to raise_error ActiveRecord::RecordNotFound
            end
          end
        end

        context 'with invalid params' do
          let(:params) { { id: box1.to_param, name: '', region: '' } }

          before { do_request(params) }

          it 'does not update the box object' do
            box1.reload
            box1.name.should_not == params[:name]
            box1.region.should_not == params[:region]
          end

          it { should respond_with :unprocessable_entity }
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
    let(:another_user) { create :user }
    let!(:box1) { create :box, users: [user] }
    let!(:box2) { create :box, users: [another_user] }

    def do_request(params={})
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          let(:params) { { id: box1.to_param } }

          it 'deletes the box object' do
            expect {
              do_request(params)
            }.to change { Box.count }.by -1

            expect {
              box1.reload
            }.to raise_error ActiveRecord::RecordNotFound
          end

          context do
            before { do_request params }

            it { should respond_with :no_content }
          end
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
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
end
