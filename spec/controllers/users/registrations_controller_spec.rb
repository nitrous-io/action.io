require 'spec_helper'

describe Users::RegistrationsController do
  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::RegistrationsController' do
    expect(Devise::RegistrationsController.subclasses).to include Users::RegistrationsController
  end

  describe 'GET new' do
    context 'when the user has a clone repo intent' do
      it 'assigns true to @clone_repo' do
        encoded_intent = {
          kind: 'clone_repo',
          data: { url: 'https://github.com/rails/rails.git' }
        }.to_query
        get :new, intent: encoded_intent

        expect(assigns(:clone_repo)).to eql true
      end
    end
  end

  describe 'GET edit' do
    let(:user) { create :user }

    before do
      sign_in user
      get :edit
    end

    it { should redirect_to "#{web_app_url}/#/account_settings" }
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

    it "saves the contents of the mixpanel 'mp_aio' cookie (except distinct_id) in the user profile" do
      request.cookies['mp_aio'] = '{"distinct_id": "chuyeow@gmail.com","initial_referrer": "$direct"}'
      do_request
      u = User.last

      expect(u.user_profile.mixpanel_properties).to eql({"initial_referrer" => "$direct"})
    end

    context "when a coupon code is provided" do
      let!(:coupon) { create :coupon, active: true }

      it "identifies the user on Mixpanel including the coupon code" do
        do_request coupon_code: coupon.code
        u = User.last
        expect(IdentifyMixpanelUserJob).to have_received(:submit_job).with(u.id, hash_including(coupon_code: coupon.code))
      end
    end

    context 'when an intent is present' do
      it 'identifies the user and tracks the sign up event on Mixpanel including the intent' do
        encoded_intent = {
          kind: 'clone_repo',
          data: { url: 'https://github.com/rails/rails.git' }
        }.to_query
        do_request intent: encoded_intent
        u = User.last
        expect(IdentifyMixpanelUserJob).to have_received(:submit_job).with(u.id, hash_including(intent: 'clone_repo'))
        expect(TrackMixpanelEventJob).to have_received(:submit_job).with('User Signed Up', u.id, hash_including(intent: 'clone_repo'))
      end
    end

    it "redirects to home page with the newly created user's email address as a param" do
      do_request
      u = User.last
      expect(controller).to redirect_to root_url(confirm_email: u.email)
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

