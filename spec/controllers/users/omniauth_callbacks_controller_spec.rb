require 'spec_helper'

shared_examples_for "an action tracks additional provider information on Mixpanel" do |endpoint, provider, omniauth_hash|
  let(:provider)      { provider }
  let(:endpoint)      { endpoint }
  let(:omniauth_hash) { omniauth_hash }

  let!(:user) { create :user }

  def track_info_klass
    case provider
    when 'twitter'  then TrackTwitterInfoOnMixpanelJob
    when 'github'   then TrackGithubInfoOnMixpanelJob
    when 'linkedin' then TrackLinkedinInfoOnMixpanelJob
    end
  end

  context "when user is signed in" do
    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      sign_in user
    end

    def do_request
      get endpoint
    end

    it "should submit a job which tracks #{provider} info on Mixpanel" do
      expect(track_info_klass).to receive(:submit_job).with(user.id)
      do_request
    end
  end

  context "when user has an invalid email" do
    before do
      sign_out :user
      omniauth_hash['info']['email'] = 'spam@example.com'
      request.env.merge!('omniauth.auth' => omniauth_hash)
    end

    def do_request
      get endpoint
    end

    it "should not submit a job which tracks #{provider} info on Mixpanel" do
      expect(track_info_klass).not_to receive(:submit_job)
      do_request
    end
  end
end

shared_examples_for "an action that handles already signed in users" do |provider, omniauth_hash|
  context 'when user is signed in already' do
    let(:omniauth_hash) { omniauth_hash }

    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      sign_in user
    end

    context 'when a matching authentication is not found' do
      it 'creates a new confirmed authentication' do
        expect {
          do_request
        }.to change { user.reload.authentications.count }.by(1)

        expect(user.authentications.last.provider).to eq(provider)
        expect(user.authentications.last.uid).to eq(omniauth_hash['uid'])
        expect(user.authentications.last.confirmed).to be_truthy
      end

      it "should set the mixpanel property is_#{provider}_authenticated to true" do
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :"is_#{provider}_authenticated", true)
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
        expect(response).to redirect_to '/app#/n2o/bonus'
      end

      it 'should redirect to the url specified in the omniauth.origin env variable' do
        # OmniAuth sets this for us when we pass an 'origin' parameter to the
        # _initial_ OmniAuth request - this behavior can only be tested in an
        # integration test.
        request.env['omniauth.origin'] = '/emma'

        do_request
        expect(response).to redirect_to '/emma'
      end

      it 'should render the popup_close template if a "oauth_popup" cookie is present' do
        request.cookies[:oauth_popup] = true

        do_request

        expect(response).to render_template('users/auth/popup_close')
        expect(response.cookies['oauth_popup']).to be_nil
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
        expect(response).to redirect_to '/app#/n2o/bonus'
      end

      it 'should redirect to the url specified in the omniauth.origin env variable' do
        # OmniAuth sets this for us when we pass an 'origin' parameter to the
        # _initial_ OmniAuth request - this behavior can only be tested in an
        # integration test.
        request.env['omniauth.origin'] = '/emma'

        do_request
        expect(response).to redirect_to '/emma'
      end

      it 'updates authentication object with new token' do
        do_request
        expect(authentication.reload.token).to eql omniauth_hash['credentials']['token']
      end

      it 'updates authentication object to be confirmed' do
        do_request
        expect(authentication.reload.confirmed).to be_truthy
      end

      it "should set the mixpanel property is_#{provider}_authenticated to true" do
        expect(SetMixpanelPropertyJob).to receive(:submit_job).with(user.id, :"is_#{provider}_authenticated", true)
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

shared_examples_for "an action that registers and authenticates external user" do |endpoint, provider, omniauth_hash|
  describe "##{endpoint}" do
    let(:endpoint)      { endpoint }
    let(:provider)      { provider }
    let(:omniauth_hash) { omniauth_hash }
    let(:user)          { create :user }

    def do_request
      get endpoint
    end

    def n2o_fill_kind
      case provider
      when "github" then N2oFill::Kind::OAUTH_GITHUB_CONNECT
      when "google" then N2oFill::Kind::OAUTH_GOOGLE_CONNECT
      when "linkedin" then N2oFill::Kind::OAUTH_LINKEDIN_CONNECT
      end
    end

    before do
      request.env.merge!('omniauth.auth' => omniauth_hash)
      SetMixpanelPropertyJob.stub(:submit_job)
      KeyValue.create key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5
    end

    context 'when user is not signed in' do
      context 'when there is an existing user authentication with the same uid and provider' do
        let!(:authentication) { create :authentication, uid: omniauth_hash['uid'], provider: provider }
        let!(:user) { authentication.user }

        context "when the user is banned" do
          before do
            authentication.update_attribute :confirmed, true
            user.ban!
          end

          it "does not log the user in" do
            do_request
            controller.should_not be_signed_in
          end
        end

        context "when the authentication is confirmed" do
          before { authentication.update_attribute :confirmed, true }

          it "logs the user in" do
            do_request
            expect(controller).to be_signed_in
            expect(controller.current_user).to eq(user)
          end

          it "redirects to the bonus page" do
            do_request
            expect(response).to redirect_to root_path
          end

          it "updates the authentication data" do
            do_request
            authentication.reload
            expect(authentication.token).to eq(omniauth_hash['credentials']['token'])
          end
        end

        context "when the authentication is not confirmed" do
          before { authentication.update_attribute :confirmed, false }

          it "does not log the user in" do
            do_request
            expect(controller).not_to be_signed_in
          end

          it "does not create a new unconfirmed authentication" do
            expect {
              do_request
            }.to_not change { Authentication.count }
          end

          it "redirects the user to the validation page for new authentication" do
            do_request
            authentication.reload
            expect(authentication).not_to be_confirmed
            expect(authentication.token).to eq(omniauth_hash['credentials']['token'])
            expect(response).to redirect_to(edit_authentication_path(
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
            expect(controller).not_to be_signed_in
          end

          it 'creates an unconfirmed authentication' do
            expect {
              do_request
            }.to change { Authentication.count }.by 1
            authentication = Authentication.last
            expect(authentication).not_to be_confirmed
          end

          it 'redirects to validation page for the new authentication' do
            do_request
            authentication = Authentication.last
            expect(response).to redirect_to(edit_authentication_path(
              authentication,
              token: omniauth_hash['credentials']['token']
            ))
          end
        end

        context "when a unconfirmed authentication is found" do
          let!(:authentication) { create :unconfirmed_authentication, user: user, provider: provider }

          it 'does not log the user in' do
            do_request
            expect(controller).not_to be_signed_in
          end

          it 'redirects to validation page for the authentication' do
            expect {
              do_request
            }.to_not change { Authentication.count }
            expect(response).to redirect_to(edit_authentication_path(
              authentication,
              token: omniauth_hash['credentials']['token']
            ))
          end
        end

        context "when a confirmed authentication entry is found" do
          let!(:authentication) { create :authentication, user: user, provider: provider }

          it 'logs the user in' do
            do_request
            expect(controller.current_user).to eq(user)
            expect(response).to redirect_to(root_path)
          end

          it 'updates the authentication data' do
            do_request
            expect(authentication.reload.token).to eq(omniauth_hash['credentials']['token'])
          end
        end
      end

      context 'when not found any matched user' do
        it 'creates a new user with new authentication' do
          expect {
            do_request
          }.to change {User.count }.by 1
          user = User.last
          expect(user.reload.email).to eq('test@gmail.com')
          expect(user.username).not_to be_present
          expect(user.encrypted_password).to be_present
          authentication = user.reload.authentications.last
          expect(authentication.provider).to eq(provider)
          expect(authentication.uid).to eq(omniauth_hash['uid'])
          expect(authentication).to be_confirmed
        end

        it 'logs the user in' do
          do_request
          expect(controller.current_user.email).to eq(omniauth_hash['info']['email'])
        end

        it 'redirects user to root_url with oauth_signup=1 query string' do
          do_request
          expect(controller).to redirect_to root_url(oauth_signup: 1)
        end
      end
    end

    it_behaves_like "an action that handles already signed in users", provider, omniauth_hash
  end
end

shared_examples_for "an action that only authenticates already signed in users" do |endpoint, provider, omniauth_hash|
  describe "##{endpoint}" do
    let(:endpoint)      { endpoint }
    let(:provider)      { provider }
    let(:omniauth_hash) { omniauth_hash }
    let(:user)          { create :user }

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
      SetMixpanelPropertyJob.stub(:submit_job)
      KeyValue.create key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5
    end

    context 'when user is not signed in' do
      it "redirects to the sign in page" do
        do_request
        expect(response).to redirect_to new_user_session_url
      end
    end

    it_behaves_like "an action that handles already signed in users", provider, omniauth_hash
  end
end

describe Users::OmniauthCallbacksController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET :github' do
    it_behaves_like "an action that registers and authenticates external user", "github", "github", {
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

    it_behaves_like "an action tracks additional provider information on Mixpanel", "github", "github", {
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
    it_behaves_like "an action that registers and authenticates external user", "google_oauth2", "google", {
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
    it_behaves_like "an action that registers and authenticates external user", "linkedin", "linkedin", {
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

    it_behaves_like "an action tracks additional provider information on Mixpanel", "github", "github", {
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
    it_behaves_like "an action that only authenticates already signed in users", "twitter", "twitter", {
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

    it_behaves_like "an action tracks additional provider information on Mixpanel", "twitter", "twitter", {
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
    it_behaves_like "an action that only authenticates already signed in users", "facebook", "facebook", {
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
