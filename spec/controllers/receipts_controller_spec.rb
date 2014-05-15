require 'spec_helper'

describe ReceiptsController do
  let(:user) { create :user }
  let(:billing_profile) { create :billing_profile, user: user }

  describe 'GET index' do
    let!(:receipt1) { create :receipt, billing_profile: billing_profile }
    let!(:receipt2) { create :receipt, billing_profile: billing_profile }
    let!(:receipt3) { create :receipt, billing_profile: billing_profile }

    let!(:another_user) { create :user }
    let!(:another_billing_profile) { create :billing_profile, user: another_user }
    let!(:receipt4) { create :receipt, billing_profile: another_billing_profile }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns only the receipts of current user as json" do
        expect(response.body).to eq({ receipts: [receipt3, receipt2, receipt1].serialize_as_hash }.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let!(:receipt1) { create :receipt, billing_profile: billing_profile }

    let!(:another_user) { create :user }
    let!(:another_billing_profile) { create :billing_profile, user: another_user }
    let!(:receipt2) { create :receipt, billing_profile: another_billing_profile }

    def do_request(params={ id: '1' })
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          before { do_request id: receipt1.to_param }

          it { should respond_with :success }
          its('response.body') { should == receipt1.serialize_as_json }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: receipt2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: '9999'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
