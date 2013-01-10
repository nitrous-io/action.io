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
    let(:user) { build :user }

    def do_request(params={})
      post :create, user: {
        email: user.email, username: user.username, invite_code: user.invite_code,
        password: '123456', password_confirmation: '123456'
      }.merge(params)
    end

    it 'sends a welcome email to user' do
      expect {
        do_request
      }.to change { Delayed::Job.count }.by(1)
      UserMailer.should_receive(:welcome).with(user.email) { stub.as_null_object }
      Delayed::Job.last.payload_object.perform
    end

    it 'increments user created metrics' do
      METRICS.should_receive(:increment).with("users.signed_up")
      do_request
    end

    it 'does not send a welcome email when user is not created' do
      expect {
        do_request invite_code: ''
      }.to_not change { Delayed::Job.count }
    end
  end
end

