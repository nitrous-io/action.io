require 'spec_helper'

describe Users::RegistrationsController do
  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::RegistrationsController' do
    Devise::RegistrationsController.subclasses.should include Users::RegistrationsController
  end

  describe 'GET #edit' do
    it 'uses dashboard layout' do
      user = create :user
      sign_in user
      get :edit
      response.should render_template("layouts/dashboard")
    end
  end

  describe 'POST #create' do
    def do_request(params={})
      post :create, user: {
        email: "i@mclov.in", username: "iamclovin",
        password: '123456', password_confirmation: '123456'
      }.merge(params)
    end

    before do
      IdentifyMixpanelUserJob.stub(:submit_job)
      TrackMixpanelEventJob.stub(:submit_job)
    end

    it "identifies the user on Mixpanel" do
      IdentifyMixpanelUserJob.should_receive(:submit_job)
      do_request
    end

    it "tracks the 'User Signed Up' event on Mixpanel" do
      TrackMixpanelEventJob.should_receive(:submit_job)
      do_request
    end
  end

  describe 'PUT #update' do
    let!(:user) { create :user, username: 'someuser' }

    def do_request(params={})
      put :update, { user: {}.merge(params), format: 'json' }
    end

    describe 'when signed in' do
      before do
        sign_in user
        do_request({ full_name: "John Doe", username: "johndoe" })
      end

      it 'filters username param' do
        expect(user.reload.username).to eq("someuser")
      end

      it { should respond_with :success }
      its('response.body') { should == user.reload.serialize_as_json(scope: user)  }
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end

