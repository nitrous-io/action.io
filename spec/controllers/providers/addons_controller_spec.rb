require 'spec_helper'

describe Providers::AddonsController do
  let!(:user) { create :user, addon_provider: true, addon_provider_has_agreed_terms: true }

  describe "GET new" do
    before do
      sign_in :user, user
    end

    def do_request(params={})
      get :new, params
    end

    context "when user has signed in and agreed to terms" do
      before { do_request }

      it { should render_template :new       }
      it { assigns(:addon).should be_present }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an addon provider'
  end

  describe "POST create" do
    before do
      sign_in :user, user
    end

    def do_request(params={ addon: {} })
      post :create, params
    end

    context "user has not agreed terms" do
      before do
        user.update_attribute(:addon_provider_has_agreed_terms, false)
      end
    end

    context "user has agreed terms" do
      context "invalid manifest JSON" do
        before { do_request(addon: { payload: 'abc' } ) }

        it { should render_template :new   }
        it { assigns(:addon).should_not be_persisted }
      end

      context "valid manifest JSON" do
        context "invalid/incomplete parameters as part of the manifest JSON" do
          before { do_request(addon: { payload: '{"id":"my_addon"}' } ) }

          it { should render_template :new       }
          it { assigns(:addon).should_not be_persisted }
        end

        context "valid parameters as part of the manifest JSON" do
          let!(:valid_manifest_json) do
<<eos
{
  "id": "action_rds_addon",
  "api": {
    "config_vars": [ "AMAZON_RDS_URL", "AMAZON_RDS_USERNAME", "AMAZON_RDS_PASSWORD", "AMAZON_RDS_HOST", "AMAZON_RDS_PORT" ],
    "required_vars": { "amazon_rds_url": "Your Amazon RDS URL (e.g. mysql://user:pass@rdshostname.amazonaws.com)" },
    "password": "dummy_password",
    "sso_salt": "dummy_sso_salt",
    "production": {
      "base_url": "https://rds.action.io/aio/resources",
      "sso_url": "https://rds.action.io/sso/login"
    },
    "test": {
      "base_url": "http://localhost:5000/aio/resources",
      "sso_url": "http://localhost:5000/sso/login"
    }
  }
}
eos
          end

          before { do_request(addon: { payload: valid_manifest_json }) }

          it { should redirect_to providers_addon_url(assigns(:addon)) }
          it { assigns(:addon).should be_persisted }
          it { assigns(:addon).owner.should == user }
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an addon provider'
  end

  describe 'GET show' do
    let(:another_user) { create :user }
    let!(:addon1) { create :addon, owner: user }
    let!(:addon2) { create :addon, owner: another_user }

    def do_request(params={ id: '1' })
      get :show, params
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the addon belongs to the current user' do
          before { do_request id: addon1.to_param }

          it { should respond_with :success }
          it { should render_template :show }
        end

        context 'when the addon belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: addon2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an addon provider'
  end

end
