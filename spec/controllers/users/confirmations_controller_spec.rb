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

      context 'when a "hack_repo" cookie is present' do
        before do
          request.cookies[:hack_repo] = 'nitrous-io/autoparts'
          request.cookies[:hack_runtime] = 'rails'
          request.cookies[:hack_file_to_open] = 'README.md'
          do_request
        end

        it 'redirects to the clone repository gateway page' do
          expect(controller).to redirect_to(hack_button_url(repo: 'nitrous-io/autoparts', runtime: 'rails', file_to_open: 'README.md'))
        end

        it 'clears the Hack on Nitrous cookies' do
          expect(cookies[:hack_repo]).to be_nil
          expect(cookies[:hack_runtime]).to be_nil
          expect(cookies[:hack_file_to_open]).to be_nil
        end
      end
    end
  end
end
