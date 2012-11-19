require 'spec_helper'

describe InvitesController do
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
        before do
          @invite_params = FactoryGirl.attributes_for(:invite, email: 'i@mclov.in')
        end

        context '(HTML)' do
          it "should redirect to the home#index page" do
            do_request(@invite_params)
            response.should redirect_to(root_path)
          end

          it "should set the flash" do
            do_request(@invite_params)
            flash[:notice].should =~ /Thank you for your interest/
          end
        end

        context '(JS)' do
          before do
            xhr_do_request(@invite_params)
          end

          it { should respond_with :success }
          it { should render_template :request_invite }
        end

        it "should create a new invite" do
          expect {
            do_request(@invite_params)
          }.to change(Invite, :count).by(1)

          Invite.first.email.should == 'i@mclov.in'
          Invite.first.ip.should == '202.157.130.10'
        end

        it "should send an email to the user with the invite confirmation and geocode the invite" do
          expect {
            do_request(@invite_params)
          }.to change { Delayed::Job.count }.by(2)

          Delayed::Job.all[0].handler.should =~ /invite_confirmation\nargs:\n- #{assigns(:invite).id}/
          Delayed::Job.all[1].handler.should =~ /GeocodeInviteJob\ninvite_id: #{assigns(:invite).id}/
        end

        context "and with a referral code (that belongs to an invite)" do
          let!(:referring_invite) { FactoryGirl.create(:invite, email: 'x@mclov.in', referral_code: 'random_referral_code') }

          before do
            @invite_params = FactoryGirl.attributes_for(:invite, email: 'i@mclov.in', referrer_code: 'random_referral_code')
          end

          it "should create a new invite with the referrer code set" do
            expect {
              do_request(@invite_params)
            }.to change(Invite, :count).by(1)

            Invite.last.email.should == 'i@mclov.in'
            Invite.last.ip.should == '202.157.130.10'
            Invite.last.referrer_code.should == 'random_referral_code'
          end
        end
      end

      context "with an invalid email address" do
        before do
          @invite_params = FactoryGirl.attributes_for(:invite, email: 'i @mclov.in')
        end

        it "should NOT create a new invite" do
          expect {
            do_request(@invite_params)
          }.to change(Invite, :count).by(0)
        end

        it "should redirect to the home#index page" do
          do_request(@invite_params)
          response.should redirect_to(root_path)
        end

        it "should set the flash" do
          do_request(@invite_params)
          flash[:notice].should =~ /invalid email/
        end

        it "should NOT send an email to the user with the invite confirmation" do
          expect {
            do_request(@invite_params)
          }.to change { Delayed::Job.count }.by(0)
        end
      end
    end

    context "when a redirect URL is specified" do
      before do
        @invite_params = FactoryGirl.attributes_for(:invite, :email => 'i@mclov.in')
      end

      it "should create a new invite" do
        expect {
          do_request(@invite_params.merge!(:redirect_url => 'http://action.io'))
        }.to change(Invite, :count).by(1)
      end

      it "should redirect to the redirect url specified" do
        do_request(@invite_params.merge!(:redirect_url => 'http://action.io'))
        response.should redirect_to('http://action.io')
      end
    end

    context "when an invite with that email address already exists" do
      before do
        FactoryGirl.create(:invite, :email => 'i@mclov.in')
        @invite_params = FactoryGirl.attributes_for(:invite, :email => 'i@mclov.in')
      end

      it "should NOT create a new invite" do
        expect {
          do_request(@invite_params)
        }.to change(Invite, :count).by(0)
      end

      it "should set the flash" do
        do_request(@invite_params)
        flash[:notice].should =~ /already requested for an invite/
      end
    end
  end

  describe "POST create" do
    let(:user) { create :user }
    let(:invite) { create :invite }
    let(:user_invitation) { stub(invite: false) }

    def do_request(email="test@email.com")
      post :create, invite: { email: email }, format: :json
    end

    context 'when the user is signed in' do
      before do
        sign_in user
        controller.stub(:current_user) { user }
        UserInvitation.stub(:new) { user_invitation }
      end

      it 'creates an invitation' do
        user_invitation.should_receive(:invite).with("test@email.com") { invite }
        do_request "test@email.com"
        should respond_with(:created)
        assigns(:invite).should eq(invite)
      end

      it 'fails when the user cannot invite anyone' do
        user_invitation.stub(:invite) { UserInvitation::NO_INVITE_LEFT }
        do_request
        should respond_with(:forbidden)
      end

      it 'fails when the invites cannot be saved' do
        invalid_invite = Invite.new
        invalid_invite.should_not be_valid
        user_invitation.stub(:invite) { invalid_invite }
        do_request
        should respond_with(:unprocessable_entity)
        assigns(:invite).should eq(invalid_invite)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
