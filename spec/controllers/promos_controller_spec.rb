require 'spec_helper'

describe PromosController do
  let(:user) { create :user }

  describe 'GET index' do
    def do_request
      get :index, code: 'buylah'
    end

    context 'when signed in' do
      before { sign_in user }
      context "when user is not a paid user" do
        before { do_request }

        it 'should apply the coupon code to the user' do
          expect(user.reload.coupon_code).to eq('buylah')
        end

        it 'should redirect the user to pricing page' do
          expect(controller).to redirect_to pricing_url
        end
      end

      context "when user is already a paid user" do
        let!(:subscription) { create :subscription, state: 'active', user: user }

        before { do_request }

        it 'should not apply the coupon code to the user' do
          expect(user.reload.coupon_code).to_not eq('buylah')
        end

        it 'should redirect the user to pricing page' do
          expect(controller).to redirect_to pricing_url
        end
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
