require 'spec_helper'

describe ConsoleController do
  let(:user) { create :user }

  describe 'GET index' do
    def do_request
      get :index
    end

    context 'when logged in' do
      let!(:box_template1) { create :box_template }
      let!(:box_template2) { create :box_template }
      let(:another_user) { create :user }
      let!(:box1) { create :box, users: [user], box_template: box_template1 }
      let!(:box2) { create :box, users: [user, another_user], box_template: box_template2 }
      let!(:box3) { create :box, users: [another_user], box_template: box_template1 }

      before do
        sign_in user
        do_request
      end

      it { should render_template 'index' }
      it { should respond_with :success }

      it { assigns(:boxes).should == [box1, box2] }
      it { assigns(:box_templates).should == [box_template1, box_template2] }
    end

    it_behaves_like 'an action that requires sign in'
  end
end
