require 'spec_helper'

shared_examples_for "an action that handles already signed in users" do |provider, omniauth_hash|
  context 'when user is signed in already' do
    before { sign_in user }

    context 'when a matching authentication is not found' do
      it 'creates a new confirmed authentication' do
        expect {
          do_request
        }.to change { user.reload.authentications.count }.by(1)

        expect(user.authentications.last.provider).to eq(provider)
        expect(user.authentications.last.uid).to eq(omniauth_hash['uid'])
        expect(user.authentications.last.confirmed).to be_true
      end

      it "should set the mixpanel property is_#{provider}_authenticated to true" do
        SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :"is_#{provider}_authenticated", true)
        do_request
      end

      it 'should give n2o bonus' do
        do_request
        last_n2o_fill = user.n2o_fills.last
        expect(last_n2o_fill.amount).to eq(KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS])
        expect(last_n2o_fill.kind).to eq(n2o_fill_kind)
      end

      it "should set the #{provider} attribute the user's bonus object to be true" do
        bonus = user.bonus
        expect(bonus.send(provider)).to be_nil

        do_request
        expect(bonus.reload.send(provider)).to be_present
      end

      it "should redirect to the bonus page" do
        do_request
        response.should redirect_to '/app#/n2o/bonus'
      end
    end

    context 'when a matching authentication is found' do
      let!(:authentication) {
        create(:authentication, provider: provider,
               uid: omniauth_hash['uid'],
               token: 'ff43201c98ffb1978c79587733e5f59a696c2a2a',
               user: user)
      }

      it 'does not create new authentication' do
        expect {
          do_request
        }.to_not change { user.reload.authentications.count }
      end

      it "should redirect to the bonus page" do
        do_request
        response.should redirect_to '/app#/n2o/bonus'
      end

      it 'updates authentication object with new token' do
        do_request
        expect(authentication.reload.token).to eql omniauth_hash['credentials']['token']
      end

      it 'updates authentication object to be confirmed' do
        do_request
        expect(authentication.reload.confirmed).to be_true
      end

      it "should set the mixpanel property is_#{provider}_authenticated to true" do
        SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :"is_#{provider}_authenticated", true)
        do_request
      end

      it 'should give n2o bonus' do
        do_request

        last_n2o_fill = user.n2o_fills.last
        expect(last_n2o_fill.amount).to eq(KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS])
        expect(last_n2o_fill.kind).to eq(n2o_fill_kind)
      end
    end
  end
end

shared_examples_for "a controller that registers and authenticates external user" do |endpoint, provider, omniauth_hash|
  describe "##{endpoint}" do
    let(:endpoint) { endpoint }
    let(:provider) { provider }
    let(:user) { create :user }

    def do_request
      get endpoint
    end

    def n2o_fill_kind
      case provider
      when "github" then N2oFill::Kind::OAUTH_GITHUB_CONNECT
      when "google" then N2oFill::Kind::OAUTH_GOOGLE_CONNECT
      when "linkedin" then N2oFill::Kind::OAUTH_LINKEDIN_CONNECT
      when "facebook" then N2oFill::Kind::OAUTH_FACEBOOK_CONNECT
      end
    end

    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      SetMixpanelPropertyJob.stub!(:submit_job)
      KeyValue.create key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5
    end

    context 'when user is not signed in' do
      context 'when there are existing user authentication with the same uid and provider' do
        let!(:authentication) { create :authentication, uid: omniauth_hash['uid'], provider: provider }
        let!(:user) { authentication.user }

        context "when the authentication is confirmed" do
          before { authentication.update_attribute :confirmed, true }

          it "logs the user in" do
            do_request
            controller.should be_signed_in
            controller.current_user.should eq(user)
          end

          it "redirects to the bonus page" do
            do_request
            response.should redirect_to root_path
          end

          it "updates the authentication data" do
            do_request
            authentication.reload
            authentication.token.should eq(omniauth_hash['credentials']['token'])
          end
        end

        context "when the authentication is not confirmed" do
          before { authentication.update_attribute :confirmed, false }

          it "does not log the user in" do
            do_request
            controller.should_not be_signed_in
          end

          it "does not create a new unconfirmed authentication" do
            expect {
              do_request
            }.to_not change { Authentication.count }
          end

          it "redirects the user to the validation page for new authentication" do
            do_request
            authentication.reload
            authentication.should_not be_confirmed
            authentication.token.should eq(omniauth_hash['credentials']['token'])
            response.should redirect_to(edit_authentication_path(
              authentication,
              token: authentication.token
            ))
          end
        end
      end

      context 'when found a matched user by email' do
        let!(:user) { create :user, email: omniauth_hash['info']['email'] }

        context "when authentication is not found" do
          before { user.authentications.destroy_all }

          it 'does not log the user in' do
            do_request
            controller.should_not be_signed_in
          end

          it 'creates an unconfirmed authentication' do
            expect {
              do_request
            }.to change { Authentication.count }.by 1
            authentication = Authentication.last
            authentication.should_not be_confirmed
          end

          it 'redirects to validation page for the new authentication' do
            do_request
            authentication = Authentication.last
            response.should redirect_to(edit_authentication_path(
              authentication,
              token: omniauth_hash['credentials']['token']
            ))
          end
        end

        context "when a unconfirmed authentication is found" do
          let!(:authentication) { create :unconfirmed_authentication, user: user, provider: provider }

          it 'does not log the user in' do
            do_request
            controller.should_not be_signed_in
          end

          it 'redirects to validation page for the authentication' do
            expect {
              do_request
            }.to_not change { Authentication.count }
            response.should redirect_to(edit_authentication_path(
              authentication,
              token: omniauth_hash['credentials']['token']
            ))
          end
        end

        context "when a confirmed authentication entry is found" do
          let!(:authentication) { create :authentication, user: user, provider: provider }

          it 'logs the user in' do
            do_request
            controller.current_user.should eq(user)
            response.should redirect_to(root_path)
          end

          it 'updates the authentication data' do
            do_request
            authentication.reload.token.should eq(omniauth_hash['credentials']['token'])
          end
        end
      end

      context 'when not found any matched user' do
        it 'creates a new user with new authentication' do
          expect {
            do_request
          }.to change {User.count }.by 1
          user = User.last
          user.reload.email.should eq('test@gmail.com')
          user.username.should_not be_present
          user.encrypted_password.should be_present
          authentication = user.reload.authentications.last
          authentication.provider.should eq(provider)
          authentication.uid.should eq(omniauth_hash['uid'])
          authentication.should be_confirmed
        end

        it 'logs the user in' do
          do_request
          expect(controller.current_user.email).to eq(omniauth_hash['info']['email'])
        end
      end
    end

    it_behaves_like "an action that handles already signed in users", provider, omniauth_hash
  end
end

shared_examples_for "a controller that only authenticates already signed in users" do |endpoint, provider, omniauth_hash|
  describe "##{endpoint}" do
    let(:endpoint) { endpoint }
    let(:provider) { provider }
    let(:user) { create :user }

    def do_request
      get endpoint
    end

    def n2o_fill_kind
      case provider
      when "twitter" then N2oFill::Kind::OAUTH_TWITTER_CONNECT
      when "facebook" then N2oFill::Kind::OAUTH_FACEBOOK_CONNECT
      end
    end

    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      SetMixpanelPropertyJob.stub!(:submit_job)
      KeyValue.create key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5
    end

    context 'when user is not signed in' do
      it "redirects to the sign in page" do
        do_request
        response.should redirect_to new_user_session_url
      end
    end

    it_behaves_like "an action that handles already signed in users", provider, omniauth_hash
  end
end

describe Users::OmniauthCallbacksController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe '#github' do
    it_behaves_like "a controller that registers and authenticates external user", "github", "github", {
      'provider' => 'github',
      'uid' => '123456',
      'info' => {
        'email' => 'test@gmail.com',
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

  describe 'GET :google_oauth2' do
    it_behaves_like "a controller that registers and authenticates external user", "google_oauth2", "google", {
      'provider' => 'google_oauth2',
      'uid' => '123456',
      'info' => {
        'email' => 'test@gmail.com',
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

  describe 'GET :linkedin' do
    it_behaves_like "a controller that registers and authenticates external user", "linkedin", "linkedin", {
      'provider' => 'linkedin',
      'uid' => '123456',
      'info' => {
        'email' => 'test@gmail.com',
        'name'  => 'John Doe',
      },
      'credentials' => {
        'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
      },
      'extra' => {
        'foo' => 'bar'
      }
    }
  end

  describe 'GET :twitter' do
    it_behaves_like "a controller that only authenticates already signed in users", "twitter", "twitter", {
      'provider' => 'twitter',
      'uid' => '123456',
      'info' => {
        'nickname' => 'johndoe',
        'name'  => 'John Doe',
      },
      'credentials' => {
        'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
      },
      'extra' => {
        'foo' => 'bar'
      }
    }
  end

  describe 'GET :facebook' do
    it_behaves_like "a controller that only authenticates already signed in users", "facebook", "facebook", {
      'provider' => 'facebook',
      'uid' => '123456',
      'info' => {
        'email' => 'test@gmail.com',
        'name'  => 'John Doe',
      },
      'credentials' => {
        'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
      },
      'extra' => {
        'foo' => 'bar'
      }
    }
  end
end
