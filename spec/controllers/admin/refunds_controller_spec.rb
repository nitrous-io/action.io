require 'spec_helper'

describe Admin::RefundsController do
  let!(:admin) { create :admin }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    let!(:refund_1) { create :refund }
    let!(:refund_2) { create :refund }
    let!(:refund_3) { create :refund }

    def do_request(params={})
      get :index, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'index' }

      it 'assigns all refund objects descended by created_at to @refunds' do
        expect(assigns(:refunds)).to eq([refund_3, refund_2, refund_1])
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET find_charges' do
    let!(:user) { create :user, stripe_customer_id: 'cus_001' }
    let!(:charge1) { OpenStruct.new(id: 'ch_001', paid: true) }
    let!(:charge2) { OpenStruct.new(id: 'ch_002', paid: false) }

    def do_request(params={})
      get :find_charges, params
    end

    context 'when signed in' do
      before do
        expect(Stripe::Charge).to receive(:all).with(customer: 'cus_001').and_return [ charge1, charge2 ]
        do_request identifier: user.username
      end

      it { should respond_with :success }
      it { should render_template 'find_charges' }

      it 'assigns successful charges to @charges' do
        expect(assigns(:charges)).to match_array([charge1])
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

      it 'assigns a new refund to @refund' do
        expect(assigns(:refund)).to be_new_record
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'POST create' do
    let!(:user) { create :user }
    let!(:refund) { build :refund }

    def do_request(params={})
      post :create, { refund: { user_id: user.id, stripe_charge_id: 'ch_xxxx', amount: '10.95', reason: "double charge" }}.merge(params)
    end

    context 'when signed in' do
      context 'when the refund is processed' do
        before do
          expect_any_instance_of(Refund).to receive(:process!) { true }

          do_request
        end

        it 'redirects user back to refunds index' do
          expect(response).to redirect_to admin_refunds_url
        end
      end

      context 'when the refund is not processed' do
        before do
          expect_any_instance_of(Refund).to receive(:process!) { false }

          do_request
        end

        it 'renders the new template' do
          expect(assigns(:refund)).to be_a_new(Refund)
          expect(controller).to respond_with :success
          expect(response).to render_template 'new'
        end
      end

    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

end

