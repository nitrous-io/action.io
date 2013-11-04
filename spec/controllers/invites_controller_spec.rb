require 'spec_helper'

describe InvitesController do
  let!(:user) { create :user }
  let!(:invite) { create :invite, inviting_user: user }
  let!(:another_invite) { create :invite }

  describe "GET index" do
    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it 'gets all invites from the current user' do
        assigns(:invites).should eq([invite])
        response.body.should == { invites: assigns(:invites).serialize_as_hash }.to_json
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe "POST create" do
    def do_request(email = "test@email.com")
      post :create, { format: 'json', invite: { email: email } }
    end

    context 'when the user is signed in' do
      before do
        sign_in user
      end

      context 'valid invitation request' do
        before do
          TrackMixpanelEventJob.stub(:submit_job)
          IncrementMixpanelPropertyJob.stub(:submit_job)

          do_request 'test@email.com'
          @invite = Invite.find_by_email("test@email.com")
        end

        it { should respond_with :created }

        it "should create a new invite object" do
          expect(@invite).to be_present
          expect(@invite.state).to eq 'activated'
          expect(@invite.inviting_user).to eq user
          expect(@invite.referral_code).to eq user.referral_code
        end

        it "should send an email to the user" do
          InviteMailer.should_receive(:send_invite).with(@invite.id) { double.as_null_object }
          Delayed::Job.last.invoke_job
        end

        its('response.body') { should == @invite.serialize_as_json }
      end

      context 'when the invite request is invalid' do
        before do
          do_request 'hello'
        end

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { error: 'invalid invite request' }.to_json }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
