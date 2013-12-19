require 'spec_helper'

describe Admin::CouponsController do
  let!(:admin) { create :admin }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    let!(:coupon_1) { create :coupon }
    let!(:coupon_2) { create :coupon }
    let!(:coupon_3) { create :coupon }

    def do_request(params={})
      get :index, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'index' }

      it 'assigns all coupon objects to @coupons' do
        expect(assigns(:coupons)).to eq([coupon_3, coupon_2, coupon_1])
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET new' do
    def do_request(params={})
      get :new, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'new' }

      it 'assigns a new coupon to @coupon' do
        expect(assigns(:coupon)).to be_new_record
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'POST create' do
    def do_request(params={})
      post :create, params
    end

    context 'when signed in' do
      before { do_request }

      context 'when the coupon is created' do
        let(:coupon) { create :coupon }

        before do
          Coupon.should_receive(:generate) { coupon }
        end

        it 'redirects user back to coupons index' do
          do_request
          expect(response).to redirect_to admin_coupons_url
        end
      end

      context 'when the coupon is not created' do
        let(:coupon) { build :coupon }

        before do
          coupon.errors.add :base, 'Some error occurred'
          Coupon.should_receive(:generate) { coupon }
        end

        it 'renders the new template' do
          do_request
          expect(assigns(:coupon)).to eq(coupon)
          expect(controller).to respond_with :success
          expect(response).to render_template 'new'
        end
      end

    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT deactivate' do
    let!(:coupon) { create :coupon }

    def do_request(params={})
      put :deactivate, { id: coupon.to_param }.merge(params)
    end

    context 'when signed in' do
      before { do_request }

      it "updates the coupon's active attribute to false" do
        expect(coupon.reload.active).to eq(false)
      end

      it 'shows a flash message' do
        flash[:notice].should =~ /Deactivated the coupon/
      end

      it 'redirects user back to coupons index' do
        expect(response).to redirect_to admin_coupons_url
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'PUT activate' do
    let!(:coupon) { create :coupon }

    def do_request(params={})
      put :activate, { id: coupon.to_param }.merge(params)
    end

    context 'when signed in' do
      before { do_request }

      it "updates the coupon's active attribute to true" do
        expect(coupon.reload.active).to eq(true)
      end

      it 'shows a flash message' do
        flash[:notice].should =~ /Activated the coupon/
      end

      it 'redirects user back to coupons index' do
        expect(response).to redirect_to admin_coupons_url
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end
end
