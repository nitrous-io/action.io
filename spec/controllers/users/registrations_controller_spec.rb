require 'spec_helper'

describe Users::RegistrationsController do
  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::RegistrationsController' do
    Devise::RegistrationsController.subclasses.should include Users::RegistrationsController
  end

  describe 'GET edit' do
    it 'uses dashboard layout' do
      user = create :user
      sign_in user
      get :edit
      response.should render_template("layouts/dashboard")
    end
  end

  describe 'POST create' do
    def do_request(params={})
      post :create, user: {
        email: "i@mclov.in", username: "iamclovin",
        password: '123456', password_confirmation: '123456'
      }.merge(params)
    end

    before do
      TrackMixpanelEventJob.stub(:submit_job)
    end

    it 'creates user' do
      expect {
        do_request
      }.to change { User.count}.by 1
      u = User.last
      expect(u.email).to eq 'i@mclov.in'
      expect(u.username).to eq 'iamclovin'
      expect(u.valid_password? '123456').to be_true
    end

    it "identifies the user on Mixpanel and then triggers 'User Signed Up' event" do
      do_request
      u = User.last
      expect(TrackMixpanelEventJob).to have_received(:submit_job).with('User Signed Up', u.id)
    end

    it "redirects to confirmation_required page with the newly created user's email address as a param" do
      do_request
      u = User.last
      expect(controller).to redirect_to users_confirmation_required_url(email: u.email)
    end
  end

  describe 'GET confirmation_required' do
    def do_request(params={})
      get :confirmation_required
    end

    it 'renders the page' do
      do_request
      expect(controller).to respond_with :ok
      expect(controller).to render_template :confirmation_required
    end
  end
end

