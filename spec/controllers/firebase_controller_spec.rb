require 'spec_helper'

describe FirebaseController do
  let(:user) { create :user }

  describe 'GET auth_token' do
    def do_request
      get :auth_token, format: 'json'
    end

    context 'when signed in' do
      let!(:firebase_secret_token) { ENV['FIREBASE_SECRET_TOKEN'] }
      let!(:generated_token) { 'firebase-token' }

      before do
        sign_in user
      end 

      after { ENV['FIREBASE_SECRET_TOKEN'] = firebase_secret_token }

      context 'when firebase secret token is not set' do
        before do
          ENV['FIREBASE_SECRET_TOKEN'] = nil
        end 

        it 'raises an exception' do
          expect {
            do_request 
          }.to raise_error
        end
      end

      context 'when firebase secret token is set' do
        before do
          ENV['FIREBASE_SECRET_TOKEN'] = '123456'

          generator = double(:generator)
          Firebase::FirebaseTokenGenerator.stub!(:new).with("123456") { generator }
          generator.stub!(:create_token).with({ user_id: user.id }, { admin: false }) { generated_token }
        end 

        it 'creates and returns an auth token' do
          do_request

          expect(response.body).to eq({
            auth_token: generated_token
          }.to_json)
        end

        it_behaves_like 'an action that is not cacheable'
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
