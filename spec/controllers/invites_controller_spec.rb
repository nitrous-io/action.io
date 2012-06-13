require 'spec_helper'

describe InvitesController do
  describe "GET new" do
    before do
      get :new
    end

    it { should respond_with :success }
    it { should render_template :new  }
    it { assigns(:invite).should be_present }
  end

  describe "POST create" do
    before do
      post :create,
    end
  end

end
