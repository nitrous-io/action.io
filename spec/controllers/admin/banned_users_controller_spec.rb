require 'spec_helper'

describe Admin::BannedUsersController do
  let!(:admin) { create :admin }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    let!(:banned_user) { create :user, banned_at: Time.now }
    let!(:not_a_banned_user) { create :user, banned_at: nil }

    def do_request(params={})
      get :index, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'index' }

      it 'finds and assign all banned users' do
        expect(assigns(:banned_users)).to eq([banned_user])
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end
end
