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
        response.body.should == { public_keys: assigns(:public_keys).serialize_as_hash }.to_json
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
        let(:params) { { public_key: {
          name: 'test@action.io',
          key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCxCeR/jJna6xXELDV8HF51QQPbj++JNDE4W/nqLyhzRTEDDnAfyp8gXW/EXXos8w5XXLak6eUDXE/QI6o8blX39RYoT47u45v4b2scN0ZiS5McmESo193KwWH3gXHbnHWywzPy7+GrRF3nHm/uidvp0tqh4ywqIZujaMjST1sIOQ== test@action.io'
        } } }

        it 'creates and persists a public key object for the current user' do
          expect {
            do_request(params)
          }.to change { PublicKey.count }.by 1

          public_key = PublicKey.last
          public_key.name.should == params[:public_key][:name]
          public_key.key.should == params[:public_key][:key]
          public_key.user.should == user
        end

        it 'sends notification email about new key to user' do
          fingerprint = "f7:de:4d:6f:54:6b:b9:d5:78:a9:62:15:e2:ad:ec:bb"
          expect {
            do_request(params)
          }.to change { Delayed::Job.count }.by 1

          PublicKeyMailer.should_receive(:save_key).
            with(user.email, 'test@action.io', fingerprint) { stub.as_null_object }
          Delayed::Job.last.payload_object.perform
        end

        context do
          before { do_request(params) }

          it { should respond_with :created }
          its('response.body') { should == PublicKey.last.serialize_as_json }
        end
      end

      context 'with invalid params' do
        let(:params) { { public_key: {} } }

        it 'does not create a public key object' do
          expect {
            do_request(params)
          }.not_to change { PublicKey.count }.by(1)
        end

        it 'does not send notification email about new key to user' do
          expect {
            do_request(params)
          }.to_not change { Delayed::Job.count }
        end

        context do
          before { do_request(params) }

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

    def do_request(params={ id: '1' })
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the public key belongs to the current user' do
          before { do_request id: key1.to_param }

          it { should respond_with :success }
          its('response.body') { should == key1.serialize_as_json }
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

    def do_request(params={ id: '1' })
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
            }.to change { PublicKey.count }.by(-1)

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
