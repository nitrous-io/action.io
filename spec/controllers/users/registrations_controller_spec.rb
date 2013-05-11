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
      new_user.received_invitations.should have(1).invite
      new_user.received_invitations.last
    end

    before do
      IdentifyMixpanelUserJob.stub(:submit_job)
      TrackMixpanelEventJob.stub(:submit_job)
    end

    context "user does not have an invite already in his name" do
      it 'creates an invite for that user with the ip of the user' do
        request.env['REMOTE_ADDR'] = '202.157.130.10'
        do_request
        find_invite_by('i@mclov.in').ip.should eq '202.157.130.10'
      end

      it 'sends an invite confirmation email to user' do
        do_request
        invite = find_invite_by('i@mclov.in')

        InviteMailer.should_receive(:send_confirmation).with(invite.id) { stub.as_null_object }
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

      it 'does not send a welcome email when user is not created' do
        expect {
          do_request email: ''
        }.to_not change { Delayed::Job.count }
      end
    end

    context "user has an invite in his name" do
      let!(:invite) { create :invite, email: 'i@mclov.in', state: 'activated' }

      it 'does not create a new invite' do
        expect {
          do_request
        }.to change(Invite, :count).by(0)
      end

      it 'sends an invite confirmation email to user' do
        do_request

        UserMailer.should_receive(:welcome).with('i@mclov.in') { stub.as_null_object }
        Delayed::Job.all.map(&:payload_object).map(&:perform)
      end

      it 'sets the state of the invite to be accepted' do
        do_request
        find_invite_by('i@mclov.in').state.should eq 'accepted'
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
end

