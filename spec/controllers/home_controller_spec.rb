require 'spec_helper'

describe HomeController do
  describe 'GET index' do
    def do_request(params = {})
      get :index, params
    end

    context 'when not signed in' do
      before { do_request }

      it { should render_template 'index' }
      it { should respond_with :success }
    end

    context 'when signed in' do
      let(:user) { create :user }

      before do
        sign_in user
        do_request
      end

      it { should redirect_to web_app_url }
    end

    context 'with a coupon_code param set' do
      context 'when coupon code exists' do
        context 'and is active' do
          let!(:coupon) { create :coupon, code: 'much-savings', active: true, description: 'Save 50%' }

          it 'should assign a coupon' do
            do_request(coupon_code: 'much-savings')
            expect(assigns(:coupon)).to eq(coupon)
          end

          context 'when coupon code is provided in upper case' do
            it 'should still assign a coupon' do
              do_request(coupon_code: 'MUCH-SAVINGS')
              expect(assigns(:coupon)).to eq(coupon)
            end
          end

          it 'should set a coupon_code cookie' do
            do_request(coupon_code: 'much-savings')
            expect(response.cookies['coupon_code']).to eq('much-savings')
          end

          it 'shows a flash message' do
            do_request(coupon_code: 'much-savings')
            should set_the_flash[:info].to(/Please sign in or sign up/).now
            should set_the_flash[:info].to(/Save 50%/).now
          end

          context 'and user is not signed in' do
            before do
              do_request(coupon_code: 'much-savings')
            end

            it { should render_template 'index' }
          end

          context 'and user is signed in' do
            let(:coupon) { create :coupon, code: 'much-savings' }
            let(:user) { create :user }

            before do
              sign_in user
              do_request(coupon_code: 'much-savings')
            end

            it { should redirect_to pricing_path }

            context 'and user is eligible for coupon' do
              before { user.stub(:eligible_for_coupon?).and_return(true) }

              it 'should apply the coupon code to the user' do
                expect(user.reload.coupon_code).to eq('much-savings')
              end
            end

            context 'and user is not eligible for coupon' do
              before { user.stub(:eligible_for_coupon?).and_return(false) }

              it 'should not apply the coupon code to the user' do
                expect(user.reload.coupon_code).to eq('much-savings')
              end
            end
          end
        end

        context 'and is not active' do
          let!(:coupon) { create :coupon, code: 'expired-coupon', active: false }

          before do
            do_request(coupon_code: 'expired-coupon')
          end

          it 'should assign a coupon' do
            expect(assigns(:coupon)).to eq(coupon)
          end

          it { should set_the_flash[:info].to(/no longer valid/).now }
        end
      end

      context 'when coupon code does not exist' do
        before do
          do_request(coupon_code: 'much-savings')
        end

        it 'should not assign a coupon' do
          expect(assigns(:coupon)).to be_nil
        end

        it { should set_the_flash[:info].to(/not a valid coupon code/).now }
      end
    end
  end

  describe 'GET ping' do
    before { get :ping }

    it { should respond_with :success }
    its('response.body') { should == 'PONG!' }
  end

  describe 'GET chat' do
    before { get :chat }

    it { should respond_with :redirect }
    it { should redirect_to 'https://www.hipchat.com/gkbrGh4Bi' }
  end

  describe 'GET pricing' do
    def do_request(params = {})
      get :pricing, params
    end

    context 'when not signed in' do
      before { do_request }

      it { should render_template 'pricing' }
      it { should respond_with :success }
    end

    context 'when signed in' do
      let(:user) { create :user }

      before do
        sign_in user
        do_request
      end

      it { should redirect_to "#{web_app_url}/#/n2o/upgrade" }
    end
  end

  describe 'GET business' do
    before { get :business }

    it { should respond_with :success }
    it { should render_template 'business' }
  end

  describe 'GET collab' do
    before { get :collab }

    it { should respond_with :success }
    it { should render_template 'collab' }
  end

  describe 'GET jobs' do
    before { get :jobs }

    it { should respond_with :success }
    it { should render_template 'jobs' }
  end

  describe 'GET team' do
    before { get :team }

    it { should respond_with :success }
    it { should render_template 'team' }
  end

  describe 'GET about' do
    before { get :about }

    it { should respond_with :success }
    it { should render_template 'about' }
  end
end
