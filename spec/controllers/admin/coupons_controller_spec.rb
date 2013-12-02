require 'spec_helper'

describe Admin::CouponsController do
  let!(:admin) { create :admin }
  let(:user) { create :user }

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
  end

  describe 'POST create' do
    def do_request(params={})
      post :create, { coupon: { code: 'hello', percent_off: 100, duration: 3, active: true } }.merge(params)
    end

    context 'with valid params' do
      before do
        Stripe::Coupon.should_receive(:create).with(
          id: 'hello',
          percent_off: 100,
          duration: 'repeating',
          duration_in_months: 3
        )
      end

      it 'creates an item' do
        expect {
          do_request
        }.to change { Coupon.count }.by(1)
        c = Coupon.last
        expect(c.code).to eq('hello')
        expect(c.percent_off).to eq(100)
        expect(c.duration).to eq(3)
        expect(c.active).to eq(true)
        expect(assigns(:coupon)).to eq(c)
        expect(response).to redirect_to admin_coupon_url(c)
      end
    end

    context 'with invalid params' do
      before do
        Stripe::Coupon.should_not_receive(:create)
      end

      it 'does not create an item' do
        expect {
          do_request coupon: { code: nil }
        }.to change { Coupon.count }.by(0)

        expect(controller).to respond_with :success
        expect(response).to render_template 'new'
      end
    end

    context 'when Stripe is down' do
      before do
        Stripe::Coupon.should_receive(:create).and_raise Stripe::APIConnectionError.new
      end

      it 'does not create an item' do
        expect {
          do_request
        }.to change { Coupon.count }.by(0)

        expect(controller).to respond_with :success
        expect(response).to render_template 'new'
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end

  describe 'GET show' do
    let!(:coupon) { create :coupon }

    def do_request(params={})
      get :show, { id: coupon.to_param }.merge(params)
    end

    context 'when an object with a given id exist' do
      before { do_request }

      it { should respond_with :success }
      it { should render_template :show }

      it 'assigns the coupon object to @coupon' do
        expect(assigns(:coupon)).to eq(coupon)
      end
    end

    context 'when an object with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:coupon) { create :coupon }

    def do_request(params={})
      delete :destroy, { id: coupon.to_param }.merge(params)
    end

    context 'when an object with a given id exist' do
      it 'deletes the item' do
        expect {
          do_request
        }.to change { Coupon.count }.by(-1)

        expect(Coupon.find_by_id(coupon.id)).to be_nil
        expect(controller).to redirect_to admin_coupons_url
      end
    end

    context 'when an object with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

end
