require 'spec_helper'

describe MixpanelController do
  describe "POST confirmation" do
    before do
      expect(Settings).to receive(:mixpanel_webhook_key).and_return 'key'
    end

    def do_request(users, event = 'event', key = 'key', params = {})
      post :confirmation, event: event, users: users.to_json, key: key
    end

    context 'without valid key' do
      it "should respond with forbidden" do
        do_request({}, 'event', 'invalid_key')
        expect(controller).to respond_with :forbidden
      end
    end

    context 'with valid key' do
      let!(:users) { Hash.new }

      it "should submit a delayed job which will handle the mixpanel webhook" do
        expect {
          do_request users
        }. to change(Delayed::Job, :count).by(1)

        job = Delayed::Job.last
        expect(job.handler).to match(/'MixpanelWebhookHandler'\nmethod_name: :handle!\nargs:\n- '#{users.to_json}'\n- event\n/)
      end

      it "should respond with 200 OK" do
        do_request users
        expect(controller).to respond_with :ok
      end
    end
  end
end
