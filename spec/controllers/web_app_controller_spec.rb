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

    def do_request
      get :index
    end

    context 'when logged in' do
      before do
        sign_in user
        do_request
      end

      it { should render_template 'index' }
      it { should respond_with :success }

      it { assigns(:boxes).should =~ [box1, box2] }
      it { assigns(:regions).should == [region1, region2] }
      it { assigns(:box_templates).should == [box_template1, box_template2] }
    end

    it_behaves_like 'an action that requires sign in'
  end
end
