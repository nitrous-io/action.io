require 'spec_helper'

describe BonusesController do
  let(:user) { create :user }

  describe 'GET show' do
    let!(:bonus) { create :bonus, user: user }

    def do_request
      get :show, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's bonus completions as json" do
        expect(response.body).to eq bonus.serialize_as_json
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT twitter_follow' do
    def do_request
      put :twitter_follow, { format: 'json' }
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it "responds with no content and call follow on twitter for the current user" do
        allow_any_instance_of(User).to receive(:follow_nitrous_on_twitter) { double.as_null_object }
        Delayed::Job.last.invoke_job
        expect(controller).to respond_with :no_content
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT send_tweet' do
    let!(:message) { 'future is in the clouds' }

    def do_request
      put :send_tweet, { message: message, format: 'json' }
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it "responds with no content and tweets composed messaged based on user's message'" do
        allow_any_instance_of(User).to receive(:send_tweet).with message
        Delayed::Job.last.invoke_job
        expect(controller).to respond_with :no_content
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE disconnect' do
    let!(:user) { create :user }
    let!(:authentication) { create :authentication, provider: 'github', user: user }
    let!(:n2o_fill) { create :n2o_fill, kind: N2oFill::Kind::OAUTH_GITHUB_CONNECT, amount: 50, user: user }
    let!(:bonus) { create :bonus, user: user, github: Time.now }

    def do_request(service='github')
      delete :disconnect, { service: service, format: 'json' }
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'for a service that does not exist or connected' do
        before { do_request('dogehub') }

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { errors: { base: ["Service not connected."] } }.to_json }
      end

      context 'when user has free n2o' do
        let!(:n2o_allocation) { create :n2o_allocation, amount: 20, user: user }

        it 'unsets the bonus timestamp for the connection' do
          do_request
          expect(bonus.reload.github).to be_nil
        end

        it "removes the n2o fill given for the connection" do
          expect {
            do_request
          }.to change { user.reload.max_n2o }.by(-50)
        end

        it "deletes the authentication" do
          expect {
            do_request
          }.to change { user.authentications.reload.count }.by(-1)
        end

        it "should respond with no content" do
          do_request
          expect(controller).to respond_with :no_content
        end
      end

      context 'when user has free n2o' do
        let!(:n2o_allocation) { create :n2o_allocation, amount: 50, user: user }

        before { do_request }

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { errors: { base: ["You are currently using all available N2O. You will need to free up some N2O to disconnect the service."] } }.to_json }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
