require 'spec_helper'

describe PublicKeysController do
  let(:user) { create :user }

  describe 'GET index' do
    let(:another_user) { create :user }
    let!(:key1) { create :public_key, user: user }
    let!(:key2) { create :public_key, user: another_user }
    let!(:key3) { create :public_key, user: user }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's public keys as json" do
        assigns(:public_keys).should =~ [key1, key3]
        response.body.should == assigns(:public_keys).to_json
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
        let(:params) { { name: 'test@action.io', key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCxCeR/jJna6xXELDV8HF51QQPbj++JNDE4W/nqLyhzRTEDDnAfyp8gXW/EXXos8w5XXLak6eUDXE/QI6o8blX39RYoT47u45v4b2scN0ZiS5McmESo193KwWH3gXHbnHWywzPy7+GrRF3nHm/uidvp0tqh4ywqIZujaMjST1sIOQ== test@action.io' } }

        it 'creates and persists a public key object for the current user' do
          expect {
            do_request(params)
          }.to change { PublicKey.count }.by 1

          public_key = PublicKey.last
          public_key.name.should == params[:name]
          public_key.key.should == params[:key]
          public_key.user.should == user
        end

        context do
          before { do_request(params) }

          it { should respond_with :created }
          its('response.body') { should == PublicKey.last.to_json }
        end
      end

      context 'with invalid params' do
        it 'does not create a public key object' do
          expect {
            do_request
          }.not_to change { PublicKey.count }.by 1
        end

        context do
          before { do_request }

          it { should respond_with :unprocessable_entity }
          it { assigns(:public_key).should_not be_persisted }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let(:another_user) { create :user }
    let!(:key1) { create :public_key, user: user }
    let!(:key2) { create :public_key, user: another_user }

    def do_request(params={})
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the public key belongs to the current user' do
          before { do_request id: key1.to_param }

          it { should respond_with :success }
          its('response.body') { should == key1.to_json }
        end

        context 'when the public key belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: key2.to_param
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
    let(:another_user) { create :user }
    let!(:key1) { create :public_key, user: user }
    let!(:key2) { create :public_key, user: another_user }

    def do_request(params={})
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the public key belongs to the current user' do
          let(:params) { { id: key1.to_param } }

          it 'deletes the public key object' do
            expect {
              do_request(params)
            }.to change { PublicKey.count }.by -1

            expect {
              key1.reload
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
              do_request id: key2.to_param
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

  describe 'POST import_github_keys' do
    def do_request
      put :import_github_keys, { format: 'json' }
    end

    context 'when signed in' do
      before do
        PublicKey.should_receive(:enqueue_import_github_keys).with(user)
        sign_in user
        do_request
      end

      it { should respond_with :no_content }
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
