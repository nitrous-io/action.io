require 'spec_helper'

describe InvitesController do
  describe "GET index" do
    let(:user) { create :user }
    let(:invite) { create :invite, inviting_user: user }
    let(:another_invite) { create :invite }

    def do_request
      get :index
    end

    it 'gets all invites from the current user' do
      sign_in user
      do_request
      assigns(:invites).should eq([invite])
      response.should be_success
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe "POST request_invite" do
    def do_request(params = {})
      post :request_invite, invite: params
    end

    def xhr_do_request(params = {})
      xhr :post, :request_invite, invite: params
    end

    before { request.env['REMOTE_ADDR'] = '202.157.130.10' }

    context "when a redirect URL is not specified" do
      context "with valid email" do
        let(:invite_params) { FactoryGirl.attributes_for(:invite, email: 'i@mclov.in') }

        context '(HTML)' do
          it "redirects to the home#index page with flash" do
            do_request invite_params
            flash[:notice].should =~ /Thank you for your interest/
            response.should redirect_to(root_path)
          end
        end

        context '(JS)' do
          it 'renders proper response' do
            xhr_do_request invite_params
            response.response_code.should eq(200)
            response.should render_template(:request_invite)
          end
        end

        context 'when enable AUTO_INVITE env variables' do
          let!(:auto_invite_setting) { ENV['AUTO_INVITE'] }
          before { ENV['AUTO_INVITE'] = 'true' }
          after { ENV['AUTO_INVITE'] = auto_invite_setting }

          it 'activates the invite' do
            do_request invite_params
            Invite.last.should be_activated
          end

          it 'sends invitation email to user' do
            do_request invite_params
            Delayed::Job.all[-1].handler.should =~ /send_invite\nargs:\n- #{assigns(:invite).id}/
          end
        end

        it "should create a new invite" do
          expect {
            do_request invite_params
          }.to change(Invite, :count).by(1)

          Invite.last.email.should == 'i@mclov.in'
          Invite.last.ip.should == '202.157.130.10'
        end

        it "should send an email to the user with the invite confirmation and geocode the invite" do
          expect {
            do_request invite_params
          }.to change { Delayed::Job.count }.by(3)

          Delayed::Job.all[0].handler.should =~ /invite_confirmation\nargs:\n- #{assigns(:invite).id}/
          Delayed::Job.all[1].handler.should =~ /GeocodeInviteJob\ninvite_id: #{assigns(:invite).id}/
          Delayed::Job.all[2].handler.should =~ /TrackMixpanelEventJob\nevent: Invite Requested/
        end

        context "and with a referral code (that belongs to an invite)" do
          let!(:referring_invite) { FactoryGirl.create(:invite, email: 'x@mclov.in', referral_code: 'random_referral_code') }
          let(:invite_params) { FactoryGirl.attributes_for(:invite, email: 'i@mclov.in', referrer_code: 'random_referral_code') }

          it "should create a new invite with the referrer code set" do
            expect {
              do_request invite_params
            }.to change(Invite, :count).by(1)

            Invite.last.email.should == 'i@mclov.in'
            Invite.last.ip.should == '202.157.130.10'
            Invite.last.referrer_code.should == 'random_referral_code'
          end
        end
      end

      context "with an invalid email address" do
        let(:invite_params) { FactoryGirl.attributes_for(:invite, email: 'i @mclov.in') }

        it "should NOT create a new invite" do
          expect {
            do_request invite_params
          }.to change(Invite, :count).by(0)
        end

        it "should redirect to the home#index page with flash" do
          do_request invite_params
          flash[:notice].should =~ /invalid email/
          response.should redirect_to(root_path)
        end

        it "should NOT send an email to the user with the invite confirmation" do
          expect {
            do_request invite_params
          }.to change { Delayed::Job.count }.by(0)
        end
      end
    end

    context "when a redirect URL is specified" do
      let(:invite_params) { FactoryGirl.attributes_for(:invite).merge!(redirect_url: 'http://action.io') }

      it "should create a new invite" do
        expect {
          do_request invite_params
        }.to change(Invite, :count).by(1)
      end

      it "should redirect to the redirect url specified" do
        do_request invite_params
        response.should redirect_to('http://action.io')
      end
    end

    context "when an invite with that email address already exists" do
      let(:invite_params) { FactoryGirl.attributes_for(:invite, :email => 'i@mclov.in') }
      before { FactoryGirl.create(:invite, :email => 'i@mclov.in') }

      it "should NOT create a new invite" do
        expect {
          do_request invite_params
        }.to change(Invite, :count).by(0)
      end

      it "should set the flash" do
        do_request invite_params
        flash[:notice].should =~ /already requested for an invite/
      end
    end
  end

  describe "POST create" do
    let(:user) { create :user }
    let(:invite) { create :invite }
    let(:user_invitation) { stub(invite: false) }

    def do_request(email="test@email.com")
      post :create, invite: { email: email }
    end

    context 'when the user is signed in' do
      before do
        sign_in user
        UserInvitation.stub(:new) { user_invitation }
      end

      it 'creates an invitation' do
        user_invitation.should_receive(:invite).with("test@email.com") { invite }
        do_request "test@email.com"
        response.should redirect_to(invites_path)
        assigns(:invite).should eq(invite)
        flash[:notice].should=~ /Invite has been sent to #{invite.email}/
      end

      it 'fails when the user cannot invite anyone' do
        user_invitation.stub(:invite) { UserInvitation::NO_INVITE_LEFT }
        do_request
        flash[:notice].should=~ /Looks like you don't have any invites left/
      end

      it 'fails when the invites cannot be saved' do
        invalid_invite = Invite.new
        invalid_invite.should_not be_valid
        user_invitation.stub(:invite) { invalid_invite }
        do_request
        flash[:notice].should=~ /Looks like you entered an invalid invite, please try again/
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
