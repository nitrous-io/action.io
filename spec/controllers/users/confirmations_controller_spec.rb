require 'spec_helper'

describe Users::ConfirmationsController do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::ConfirmationsController' do
    expect(Devise::ConfirmationsController.subclasses).to include Users::ConfirmationsController
  end

  describe '#show' do
    let!(:user) { create :user }

    def do_request(params={})
      get :show, ({ confirmation_token: 'abcdef' }).merge(params)
    end

    context 'when confirmation token matches a user' do
      before do
        User.stub(:confirm_by_token).with('abcdef') { user }
      end

      it 'should redirect to root_url' do
        do_request

        expect(controller).to redirect_to(root_url)
      end

      context 'when a coupon_code cookie is present' do
        before do
          request.cookies['coupon_code'] = 'much-savings'
          do_request
        end

        it 'should redirect to pricing page' do
          expect(controller).to redirect_to(pricing_path)
        end
      end

      context 'when a "hack" cookie is present' do
        before do
          request.cookies[:hack] = '/some/path%3Frepo%3Dnitrous-io/autoparts'
          do_request
        end

        it 'redirects to the path in the "hack" cookie' do
          expect(controller).to redirect_to('/some/path%3Frepo%3Dnitrous-io/autoparts')
        end

        it 'clears the "hack" cookie' do
          expect(cookies[:hack]).to be_nil
        end
      end
    end
  end
end
