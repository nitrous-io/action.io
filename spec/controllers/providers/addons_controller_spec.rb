require 'spec_helper'

describe Providers::AddonsController do
  let(:user) { create :user, addon_provider: true, addon_provider_has_agreed_terms: true }
  let(:valid_manifest_json) do
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

  describe 'POST create' do
    before { sign_in :user, user }

    def do_request(params={ addon: {} })
      post :create, params, format: :json, access_token: token
    end

    context 'user has not agreed terms' do
      before { user.update_attribute(:addon_provider_has_agreed_terms, false) }
    end

    context 'user has agreed terms' do
      context 'no access token' do
        context 'invalid manifest JSON' do
          it_behaves_like 'an action that returns 401 when without an access token' do
            let(:payload) { { addon: { payload: 'abc' } } }
          end
        end

        context 'valid manifest JSON' do
          context 'invalid/incomplete parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 401 when without an access token' do
              let(:payload) { { addon: { payload: '{"id":"my_addon"}' } } }
            end
          end

          context 'valid parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 401 when without an access token' do
              let(:payload) { { addon: { payload: valid_manifest_json } } }
            end
          end
        end
      end

      context 'invalid access token' do
        context 'invalid manifest JSON' do
          it_behaves_like 'an action that returns 401 with an invalid access token' do
            let(:payload) { { addon: { payload: 'abc' } } }
          end
        end

        context 'valid manifest JSON' do
          context 'invalid/incomplete parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 401 with an invalid access token' do
              let(:payload) { { addon: { payload: '{"id":"my_addon"}' } } }
            end
          end

          context 'valid parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 401 with an invalid access token' do
              let(:payload) { { addon: { payload: valid_manifest_json } } }
            end
          end
        end
      end

      context 'access token with invalid scope' do
        context 'invalid manifest JSON' do
          it_behaves_like 'an action that returns 401 with an access token with invalid scope' do
            let(:payload) { { addon: { payload: 'abc' } } }
          end
        end

        context 'valid manifest JSON' do
          context 'invalid/incomplete parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 401 with an access token with invalid scope' do
              let(:payload) { { addon: { payload: '{"id":"my_addon"}' } } }
            end
          end

          context 'valid parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 401 with an access token with invalid scope' do
              let(:payload) { { addon: { payload: valid_manifest_json } } }
            end
          end
        end
      end

      context 'valid access token' do
        let(:token) do
          stub :accessible? => true,
          :scopes => [:addons],
          :resource_owner_id => user.id
        end

        before do
          controller.stub(:doorkeeper_token) { token }
        end

        context 'invalid manifest JSON' do
          it_behaves_like 'an action that returns 403 with an invalid manifest' do
            let(:payload) { { addon: { payload: 'abc' } } }
          end
        end

        context 'valid manifest JSON' do
          context 'invalid/incomplete parameters as part of the manifest JSON' do
            it_behaves_like 'an action that returns 403 with an invalid manifest' do
              let(:payload) { { addon: { payload: '{"id":"my_addon"}' } } }
            end
          end

          context 'valid parameters as part of the manifest JSON' do
            let(:payload) { {addon: { payload: valid_manifest_json } } }

            it 'should return 200' do
              do_request(payload)
              expect(response.status).to eq(200)
            end

            it 'should save the addon' do
              expect {
                do_request(payload)
              }.to change { Addon.count }.by(1)
            end
          end
        end
      end

    end
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
  end
end
