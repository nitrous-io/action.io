require 'spec_helper'

describe OrgsController do
  let!(:user) { create :user }

  describe 'POST create' do
    def do_request(params={})
      post :create, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let!(:params) { { org: {
          name: 'Nitrous.IO',
          billing_email: 'billing@nitrous.io'
        } } }

        it 'creates and persists an org' do
          expect {
            do_request(params)
          }.to change { Org.count }.by 1

          org = Org.last
          expect(org.name).to eql params[:org][:name]
          expect(org.billing_email).to eql params[:org][:billing_email]
          expect(org.owner).to eql user
        end

        it 'increments the mixpanel property orgs' do
          expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :orgs, 1)
          do_request(params)
        end

        it 'tracks the event "Org Created"' do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with('Org Created', user.id)
          do_request(params)
        end

        context do
          before { do_request(params) }

          it { should respond_with :created }
          its('response.body') { should == Org.last.serialize_as_json }
        end
      end

      context 'with invalid params' do
        it 'does not create an org' do
          expect {
            do_request
          }.not_to change { Org.count }.by 1
        end

        context do
          before { do_request }

          it { should respond_with :unprocessable_entity }
          it { expect(assigns(:org)).not_to be_persisted }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

end
