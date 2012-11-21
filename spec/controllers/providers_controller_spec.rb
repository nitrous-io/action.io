require 'spec_helper'

describe ProvidersController do
  let!(:user) { create :user, addon_provider: true }

  describe "GET index" do
    before do
      sign_in :user, user
    end

    def do_request(params = {})
      get :index, params
    end

    context "user has not agreed to the provider terms" do
      before do
        do_request
      end

      it { should redirect_to show_terms_providers_path }
    end

    context "user has agreed to the provider terms" do
      before do
        user.update_attribute(:addon_provider_has_agreed_terms, true)
        do_request
      end

      it { should respond_with :success }
      it { should render_template :index }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an addon provider'
  end

  describe "GET show_terms" do
    before do
      sign_in :user, user
    end

    def do_request(params = {})
      get :show_terms, params
    end

    context "user has agreed to the provider terms" do
      before do
        user.update_attribute(:addon_provider_has_agreed_terms, true)
        do_request
      end

      it { should redirect_to providers_path }
    end

    context "user has not agreed to the provider terms" do
      before do
        do_request
      end

      it { should render_template :show_terms }
      it { should respond_with :success }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an addon provider'
  end

  describe "POST agree_terms" do
    before do
      sign_in :user, user
    end

    def do_request(params = {})
      post :agree_terms, params
    end

    context "user has agreed to the provider terms" do
      it "should set the addon_provider_has_agreed_terms flag to true" do
        expect {
          do_request(agree: true)
          user.reload
        }.to change { user.addon_provider_has_agreed_terms }.from(false).to(true)
      end

      it "should redirect to providers_path" do
        do_request(agree: true)
        response.should redirect_to providers_path
      end
    end

    context "user has not agreed to the provider terms" do
      it "should not change the addon_provider_has_agreed_terms flag to true" do
        expect {
          do_request(agree: false)
        }.not_to change(user, :addon_provider_has_agreed_terms)
      end

      it "should redirect to show_terms page" do
        do_request(agree: false)
        response.should redirect_to show_terms_providers_path
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an addon provider'
  end
end
