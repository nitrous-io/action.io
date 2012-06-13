require 'spec_helper'

describe BoxesController do
  let(:user) { create :user_with_invite }

  describe 'GET index' do
    let(:another_user) { create :user_with_invite }
    let!(:box1) { create :box, owner: user,         users: [user] }
    let!(:box2) { create :box, owner: another_user, users: [another_user] }
    let!(:box3) { create :box, owner: another_user, users: [user, another_user] }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's boxes as json" do
        assigns(:boxes).should =~ [box1, box3]
        response.body.should == assigns(:boxes).to_json
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
        let(:box_template) { create :box_template }
        let(:region) { create :region }
        let(:params) { { name: 'fragrant-wind-69', region_id: region.to_param, box_template_id: box_template.to_param } }

        it 'creates and persists a box object for the current user' do
          expect {
            do_request(params)
          }.to change { Box.count }.by 1

          box = Box.last
          box.name.should == params[:name]
          box.region.should == region
          box.box_template.should == box_template
          box.users.should == [user]
          box.owner.should == user
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
    let(:another_user) { create :user_with_invite }
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
    let(:another_user) { create :user_with_invite }
    let(:region1) { create :region }
    let(:region2) { create :region }
    let!(:box1) { create :box, users: [user], name: 'twilight-waterfall-42', region_id: region1.to_param }
    let!(:box2) { create :box, users: [another_user] }

    def do_request(params={})
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'with valid params' do
          let(:params) { { name: 'fragrant-wind-69', region_id: region2.to_param } }

          context 'when the box belongs to the current user' do
            before { do_request params.merge(id: box1.to_param) }

            it 'updates the box object' do
              box1.reload
              box1.name.should == params[:name]
              box1.region.should == region2
            end

            it { should respond_with :success }
            its('response.body') { should == box1.reload.to_json }
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
          let(:params) { { id: box1.to_param, name: '' } }

          before { do_request(params) }

          it 'does not update the box object' do
            box1.reload
            box1.name.should_not == params[:name]
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
    let(:another_user) { create :user_with_invite }
    let!(:box1) { create :box, users: [user], state: 'stopped' }
    let!(:box2) { create :box, users: [another_user], state: 'stopped' }

    def do_request(params={})
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          let(:params) { { id: box1.to_param } }

          before do
            Box.any_instance.should_receive(:enqueue_terminate!)
            do_request params
          end

          it { should respond_with :no_content }
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

  describe 'GET terminal' do
    let!(:another_user) { create :user_with_invite }
    let!(:box1) { create :box, owner: user,         users: [user] }
    let!(:box2) { create :box, owner: another_user, users: [another_user] }
    let!(:box3) { create :box, owner: user,         users: [user] }

    def do_request(params={})
      get :terminal, params
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          before { do_request id: box1.to_param }

          it { should respond_with :success }
          it { assigns(:box).should == box1 }
          it { should render_template 'terminal' }

          it "sets proper _aio_tty_keys cookie with HMAC-SHA1'ed user id for each of the user's boxes" do
            tty_keys_hash = {}
            [box1, box3].each do |box|
              verifier = ActiveSupport::MessageVerifier.new(box.key, serializer: Serializers::JSONSerializer)
              tty_keys_hash[box.id.to_s] = verifier.generate(user.id.to_s)
            end
            cookies['_aio_tty_keys'].should_not be_blank
            cookie = cookies.instance_variable_get(:@set_cookies)['_aio_tty_keys']
            cookie[:domain].should == '.example.com'
            cookie[:httponly].should be_true
            JSON.parse(Base64.decode64(cookies['_aio_tty_keys'])).should == tty_keys_hash
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

    it_behaves_like 'an action that requires sign in'
  end

  shared_examples 'a box control action' do |options|
    action = options[:action]
    previous_state = options[:previous_state]

    let(:another_user) { create :user_with_invite }
    let!(:box1) { create :box, users: [user], state: previous_state }
    let!(:box2) { create :box, users: [another_user], state: previous_state }

    define_method :do_request do |params={}|
      put action, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          let(:params) { { id: box1.to_param } }

          before do
            Box.any_instance.should_receive(:"enqueue_#{action}!")
            do_request params
          end

          it { should respond_with :success }
          its('response.body') { should == box1.reload.to_json }
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

  describe 'PUT start' do
    it_behaves_like 'a box control action', action: :start,   previous_state: :stopped
  end

  describe 'PUT suspend' do
    it_behaves_like 'a box control action', action: :suspend, previous_state: :running
  end

  describe 'PUT resume' do
    it_behaves_like 'a box control action', action: :resume,  previous_state: :suspended
  end

  describe 'PUT stop' do
    it_behaves_like 'a box control action', action: :stop,    previous_state: :running
  end
end
