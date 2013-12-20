require 'spec_helper'

describe N2oController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:n2o_fill)   { create :n2o_fill, user: user, amount: 200 }
    let!(:n2o_fill2)  { create :n2o_fill, user: user, amount: -50 }
    let!(:n2o_fill3)  { create :n2o_fill, user: user, amount: 300 }
    let!(:n2o_alloc)  { create :n2o_allocation, user: user, amount: 150 }
    let!(:n2o_alloc2) { create :n2o_allocation, user: user, amount:  25, deallocated_at: Time.now }
    let!(:n2o_alloc3) { create :n2o_allocation, user: user, amount: 100 }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's n2o usage as json" do
        expect(response.body).to eq({ n2o: { max: 450, used: 250 } }.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
