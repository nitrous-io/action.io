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
        User.any_instance.should_receive(:follow_nitrous_on_twitter) { stub.as_null_object }
        Delayed::Job.last.invoke_job
        expect(controller).to respond_with :no_content
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
