require 'spec_helper'

describe InvitesController do
  describe "POST request_invite" do
    def do_request(params = {})
      post :request_invite, :invite => params
    end

    context "when a redirect URL is not specified" do
      context "with valid email" do
        before do
          @invite_params = FactoryGirl.attributes_for(:invite, :email => 'i@mclov.in')
        end

        it "should create a new invite" do
          expect {
            do_request(@invite_params)
          }.to change(Invite, :count).by(1)
        end

        it "should redirect to the home#index page" do
          do_request(@invite_params)
          response.should redirect_to(root_path)
        end

        it "should set the flash" do
          do_request(@invite_params)
          flash[:notice].should =~ /Thank you for your interest/
        end

        it "should send an email to the user with the invite confirmation" do
          expect {
            do_request(@invite_params)
          }.to change { Delayed::Job.count }.by(1)

          Delayed::Job.first.handler.should =~ /invite_confirmation\nargs:\n- i@mclov\.in/
        end
      end

      context "with an invalid email address" do
        before do
          @invite_params = FactoryGirl.attributes_for(:invite, :email => 'i @mclov.in')
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

end
