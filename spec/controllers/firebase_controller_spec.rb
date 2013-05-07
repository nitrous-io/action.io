require 'spec_helper'

describe FirebaseController do
  let(:user) { create :user }
  let(:another_user) { create :user }

  let!(:box1) { create :box, users: [user, another_user] }
  let!(:box2) { create :box, users: [another_user] }

  describe 'GET auth_token' do
    def do_request(params={ box_id: '1' })
      get :auth_token, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      let!(:firebase_secret_token) { ENV['FIREBASE_SECRET_TOKEN'] }
      let!(:generated_token) { 'firebase-token' }

      before do
        sign_in user
      end

      after { ENV['FIREBASE_SECRET_TOKEN'] = firebase_secret_token }

      context 'when the box belongs to the current user' do
        context 'when firebase secret token is not set' do
          before do
            ENV['FIREBASE_SECRET_TOKEN'] = nil
          end

          it 'raises an exception' do
            expect {
              do_request box_id: box1.to_param
            }.to raise_error
          end
        end

        context 'when firebase secret token is set' do
          before do
            ENV['FIREBASE_SECRET_TOKEN'] = '123456'

            generator = double(:generator)
            Firebase::FirebaseTokenGenerator.stub!(:new).with("123456") { generator }
            generator.stub!(:create_token).with({ user_id: user.to_param, box_id: box1.to_param }, { admin: false }) { generated_token }
          end

          it 'creates and returns an auth token' do
            do_request box_id: box1.to_param

            expect(response.body).to eq({
              auth_token: generated_token
            }.to_json)
          end

          it_behaves_like 'an action that is not cacheable'
        end
      end

      context 'when the box does not belongs to the current user' do
        it 'raises record not found' do
          expect {
            do_request id: box2.to_param
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
