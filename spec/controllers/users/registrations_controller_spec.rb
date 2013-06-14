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

    def find_invite_by(email)
      new_user = User.find_by_email "i@mclov.in"
      new_user.received_invites.should have(1).invite
      new_user.received_invites.last
    end

    before do
      IdentifyMixpanelUserJob.stub(:submit_job)
      TrackMixpanelEventJob.stub(:submit_job)
    end

    it 'sends an invite confirmation email to user' do
      do_request

      UserMailer.should_receive(:welcome).with('i@mclov.in') { stub.as_null_object }
      Delayed::Job.all.map(&:payload_object).map(&:perform)
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
end

