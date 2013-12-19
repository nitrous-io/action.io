require 'spec_helper'

describe Users::RegistrationsController do
  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::RegistrationsController' do
    expect(Devise::RegistrationsController.subclasses).to include Users::RegistrationsController
  end

  describe 'GET edit' do
    it 'uses dashboard layout' do
      user = create :user
      sign_in user
      get :edit
      expect(response).to render_template("layouts/dashboard")
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
      IdentifyMixpanelUserJob.stub(:submit_job)
    end

    it 'creates user' do
      expect {
        do_request
      }.to change { User.count}.by 1
      u = User.last
      expect(u.email).to eq 'i@mclov.in'
      expect(u.username).to eq 'iamclovin'
      expect(u.valid_password? '123456').to be_truthy
    end

    it "identifies the user on Mixpanel and then triggers 'User Signed Up' event" do
      do_request
      u = User.last
      expect(IdentifyMixpanelUserJob).to have_received(:submit_job).with(u.id, {})
      expect(TrackMixpanelEventJob).to have_received(:submit_job).with('User Signed Up', u.id, {})
    end

    it "identifies the user on Mixpanel with the contents of the 'mp_aio' cookie" do
      request.cookies['mp_aio'] = '{"distinct_id": "chuyeow@gmail.com","initial_referrer": "$direct"}'
      do_request
      u = User.last
      expect(IdentifyMixpanelUserJob).to have_received(:submit_job).with(u.id, 'distinct_id' => 'chuyeow@gmail.com', 'initial_referrer' => '$direct')
    end

    context "when a coupon code is provided" do
      let!(:coupon) { create :coupon, active: true }

      it "identifies the user on Mixpanel including the coupon code" do
        do_request(coupon_code: coupon.code)
        u = User.last
        expect(IdentifyMixpanelUserJob).to have_received(:submit_job).with(u.id, hash_including('coupon_code' => coupon.code))
      end
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

