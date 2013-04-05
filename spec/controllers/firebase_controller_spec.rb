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
        ENV['FIREBASE_SECRET_TOKEN'] = '123456'
        generator = double(:generator)
        Firebase::FirebaseTokenGenerator.stub!(:new).with("123456") { generator }
        generator.stub!(:create_token).with({ user_id: user.id }, { admin: false }) { generated_token }

        sign_in user
      end 
      after { ENV['FIREBASE_SECRET_TOKEN'] = firebase_secret_token }

      it 'creates and returns an auth token' do
        do_request

        expect(response.body).to eq({
          auth_token: generated_token
        }.to_json)
      end

      it_behaves_like 'an action that is not cacheable'
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
