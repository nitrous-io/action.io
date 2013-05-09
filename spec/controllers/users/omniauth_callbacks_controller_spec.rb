require 'spec_helper'

describe Users::OmniauthCallbacksController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe '#github' do
    let(:user) { create :user }

    def do_request
      get :github
    end

    let!(:omniauth_hash) do
      {
        'provider' => 'github',
        'uid' => '123456',
        'info' => {
          'email' => 'test@example.com',
          'name'  => 'John Doe',
          'nickname' => 'johndoe'
        },
        'credentials' => {
          'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        },
        'extra' => {
          'foo' => 'bar'
        }
      }
    end

    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      SetMixpanelPropertyJob.stub!(:submit_job)
    end

    context 'when user is not logged in' do
      context 'when found a matched user' do
        let!(:user) { create :user, email: "test@example.com" }

        it 'logs the user in' do
          do_request
          controller.current_user.should eq(user)
          response.should redirect_to(root_path)
        end

        it 'updates the authentication data' do
          do_request
          token = user.reload.authentications.last.token
          token.should eq('b27e7786caf89a6373a3799fa9a57e4558dc2363')
        end
      end

      context 'when not found any matched user' do
        it 'creates a new user with new authentication' do
          expect {
            do_request
          }.to change {User.count }.by 1
          user = User.last
          user.reload.email.should eq('test@example.com')
          user.username.should_not be_present
          user.encrypted_password.should be_present
          authentication = user.reload.authentications.last
          authentication.provider.should eq("github")
          authentication.uid.should eq('123456')
        end

        it 'logs the user in' do
          do_request
          controller.current_user.email.should eq("test@example.com")
        end
      end
    end

    context 'when user is logged in already' do
      before { sign_in user }

      context 'when a matching authentication is not found' do
        it 'creates a new authentication' do
          expect {
            do_request
          }.to change { user.reload.authentications.count }.by(1)
          user.authentications.last.provider.should eq('github')
          user.authentications.last.uid.should eq('123456')
        end

        it 'should set the mixpanel property is_github_authenticated to true' do
          SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :is_github_authenticated, true)
          do_request
        end
      end

      context 'when a matching authentication is found' do
        let!(:authentication) {
          create(:authentication, provider: 'github',
                 uid: '123456', token: 'ff43201c98ffb1978c79587733e5f59a696c2a2a',
                 user: user)
        }

        it 'does not create new authentication' do
          expect {
            do_request
          }.to_not change { user.reload.authentications.count }
        end

        it 'updates authentication object with new token' do
          do_request
          authentication.reload.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        end

        it 'should set the mixpanel property is_github_authenticated to true' do
          SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :is_github_authenticated, true)
          do_request
        end
      end
    end
  end

  describe 'GET :google_oauth2' do

    def do_request
      get :google_oauth2
    end

    let!(:omniauth_hash) do
      {
        'provider' => 'google_oauth2',
        'uid' => '123456',
        'info' => {
          'email' => 'test@example.com',
          'name'  => 'John Doe',
          'nickname' => 'johndoe'
        },
        'credentials' => {
          'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        },
        'extra' => {
          'foo' => 'bar'
        }
      }
    end

    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      SetMixpanelPropertyJob.stub!(:submit_job)
    end

    context 'when user is not logged in' do
      context 'when found a matched user' do
        let!(:user) { create :user, email: "test@example.com" }

        it 'logs the user in' do
          do_request
          controller.current_user.should eq(user)
          response.should redirect_to(root_path)
        end

        it 'updates the authentication data' do
          do_request
          token = user.reload.authentications.last.token
          token.should eq('b27e7786caf89a6373a3799fa9a57e4558dc2363')
        end
      end

      context 'when not found any matched user' do
        it 'creates a new user with new authentication' do
          expect {
            do_request
          }.to change {User.count }.by 1
          user = User.last
          user.reload.email.should eq('test@example.com')
          user.username.should_not be_present
          user.encrypted_password.should be_present
          authentication = user.reload.authentications.last
          authentication.provider.should eq("google_oauth2")
          authentication.uid.should eq('123456')
        end

        it 'logs the user in' do
          do_request
          controller.current_user.email.should eq("test@example.com")
        end
      end
    end

    context 'when user is logged in already' do
      let!(:user) { create :user }
      before { sign_in user }

      context 'when a matching authentication is not found' do
        it 'creates a new authentication' do
          expect {
            do_request
          }.to change { user.reload.authentications.count }.by(1)
          user.authentications.last.provider.should eq('google_oauth2')
          user.authentications.last.uid.should eq('123456')
        end

        it 'should set the mixpanel property is_google_authenticated to true' do
          SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :is_google_authenticated, true)
          do_request
        end
      end

      context 'when a matching authentication is found' do
        let!(:authentication) {
          create(:authentication, provider: 'google_oauth2',
                 uid: '123456', token: 'ff43201c98ffb1978c79587733e5f59a696c2a2a',
                 user: user)
        }

        it 'does not create new authentication' do
          expect {
            do_request
          }.to_not change { user.reload.authentications.count }
        end

        it 'updates authentication object with new token' do
          do_request
          authentication.reload.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        end

        it 'should set the mixpanel property is_google_authenticated to true' do
          SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :is_google_authenticated, true)
          do_request
        end
      end
    end
  end
end
