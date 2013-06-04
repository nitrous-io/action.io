require 'spec_helper'

describe WebAppController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:another_user) { create :user }
    let!(:region1) { create :region, enabled: true }
    let!(:region2) { create :region, enabled: true }
    let!(:region3) { create :region }
    let!(:box_template1) { create :box_template }
    let!(:box_template2) { create :box_template }
    let!(:box1) { create :box, box_template: box_template1, users: [user], region: region1 }
    let!(:box2) { create :box, box_template: box_template1, users: [user, another_user], region: region1 }
    let!(:box3) { create :box, box_template: box_template2, users: [another_user], region: region1 }
    let!(:box4) { create :box, box_template: box_template1, users: [user], region: region1 }
    let!(:box5) { create :box, box_template: box_template1, users: [user], region: region1 }

    def do_request
      get :index
    end

    context 'when logged in' do
      before do
        sign_in user
        Timecop.freeze do
          box4.update_attribute :terminated_at, 1.day.ago + 1.second
          box5.update_attribute :terminated_at, 1.day.ago
          do_request
        end
      end

      it { should render_template 'index' }
      it { should respond_with :success }

      it { assigns(:boxes).should =~ [box1, box2, box4] }
      it { assigns(:regions).should == [region1, region2] }
      it { assigns(:box_templates).should == [box_template1, box_template2] }

      context 'when the invite is set to "activated"' do
        before do
          @invite = Invite.find_by_email(user.email)
          @invite.update_attribute(:state, 'activated')
        end

        it "should change the state of the invite from 'activated' to 'accepted'" do
          expect {
            do_request
            @invite.reload
          }.to change(@invite, :state).from('activated').to('accepted')
        end
      end
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe GET logged_in do
    def do_request
      post :logged_in
    end

    context 'when logged in' do
      it 'updates hide_boxes_tour attribute for the current user' do
        do_request
        controller.should respond_with :success
        expect(response.headers['Cache-Control']).to eq('no-cache')
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end

    it_behaves_like 'an action that requires sign in'
  end

end
