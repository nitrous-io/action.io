require 'spec_helper'

describe Admin::InvitesController do
  let(:user)  { create :user }
  let(:admin) { create :admin }

  describe "GET index" do
    def do_request(params = {})
      get :index, params
    end

    context 'when signed in as admin' do
      let!(:invite1) { Invite.find_by_email(user.email) }
      let!(:invite2) { create :invite }
      let!(:invite3) { create :invite, state: 'activated' }
      let!(:invite4) { create :invite, state: 'accepted' }
      let!(:invite5) { create :invite, state: 'accepted', city: 'San Francisco', country: 'United States' }
      let!(:invite6) { create :invite, city: 'San Francisco', country: 'United States' }
      let!(:invite7) { create :invite, city: 'New York', country: 'United States'  }

      before do
        sign_in admin
      end

      context 'when no filter is present' do
        before { do_request }

        it { should respond_with :success   }
        it { should render_template :index  }
        it { assigns(:invites).should =~ [invite2, invite6, invite7] }
      end

      context 'when filter is activated' do
        before { do_request(filter: 'activated') }

        it { should respond_with :success   }
        it { should render_template :index  }
        it { assigns(:invites).should == [invite3] }
      end

      context 'when filter is accepted' do
        before { do_request(filter: 'accepted') }

        it { should respond_with :success   }
        it { should render_template :index  }
        it { assigns(:invites).should == [invite5, invite4, invite1] }
      end

      context 'when search is defined (for city)' do
        before { do_request(q: 'San Francisco') }

        it { should respond_with :success }
        it { should render_template :index }
        it { assigns(:invites).should == [invite6] }
      end

      context 'when search is defined (for country)' do
        before { do_request(q: 'United States') }

        it { should respond_with :success }
        it { should render_template :index }
        it { assigns(:invites).should == [invite7, invite6] }
      end

      context 'when search is defined (for country) and a filter is defined' do
        before { do_request(q: user.email, filter: 'accepted') }

        it { should respond_with :success }
        it { should render_template :index }
        it { assigns(:invites).should == [invite1] }
      end

      context 'when search is defined (for email)' do
        before { do_request(q: 'United States', filter: 'accepted') }

        it { should respond_with :success }
        it { should render_template :index }
        it { assigns(:invites).should == [invite5] }
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end

  describe "POST send_invite" do
    def do_request(params = { id: 1 })
     post :send_invite, params
    end

    context 'when signed in as an admin' do
      before { sign_in admin }

      context 'when an invite with a given id does not exist' do
        it 'raises record not found exception' do
          expect {
            do_request id: 99999
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context "with a pending invite" do
        let(:invite) { create :invite, state: 'pending', email: 'aj@action.io'}

        before { do_request id: invite.to_param }

        it { should redirect_to invites_url }

        it 'activates the invite and generates an invite code' do
          invite.reload.state.should == 'activated'
          invite.invite_code.should_not be_nil
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /Your invite was sent/
        end

        it "should send an email to the user with the invite code in the invite" do
          expect {
            do_request
          }.to change { Delayed::Job.count }.by(2)

          Delayed::Job.all[0].handler.should =~ /send_invite\nargs:\n- #{assigns(:invite).id}/
          Delayed::Job.all[1].handler.should =~ /TrackMixpanelEventJob\nevent: Invite Sent\nuser_id: \nproperties:\n  :email: aj@action.io\n/
        end
      end

      context 'with an activated invite' do
        let(:invite) { create :invite, state: 'activated', invite_code: 'foobarbaz', email: 'aj@action.io' }

        before { do_request id: invite.to_param }

        it { should redirect_to invites_url }

        it 'asserts the invite is activated and invite code exists' do
          invite.reload.state.should == 'activated'
          invite.invite_code.should_not be_nil
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /Your invite was sent/
        end

        it 'sends an email to the invited user' do
          expect {
            do_request
          }.to change { Delayed::Job.count }.by(2)

          Delayed::Job.all[0].handler.should =~ /send_invite\nargs:\n- #{assigns(:invite).id}/
          Delayed::Job.all[1].handler.should =~ /TrackMixpanelEventJob\nevent: Invite Sent\nuser_id: \nproperties:\n  :email: aj@action.io\n/
        end
      end

      context 'with the return_url set' do
        let(:invite) { create :invite, state: 'activated', invite_code: 'foobarbaz', email: 'aj@action.io' }

        before { do_request id: invite.to_param, return_url: 'https://action.io' }

        it { should redirect_to 'https://action.io' }

        it 'asserts the invite is activated and invite code exists' do
          invite.reload.state.should == 'activated'
          invite.invite_code.should_not be_nil
        end

        it 'shows a flash message' do
          flash[:notice].should =~ /Your invite was sent/
        end

        it 'sends an email to the invited user' do
          expect {
            do_request
          }.to change { Delayed::Job.count }.by(2)

          Delayed::Job.all[0].handler.should =~ /send_invite\nargs:\n- #{assigns(:invite).id}/
          Delayed::Job.all[1].handler.should =~ /TrackMixpanelEventJob\nevent: Invite Sent\nuser_id: \nproperties:\n  :email: aj@action.io\n/
        end
      end

    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end
end
