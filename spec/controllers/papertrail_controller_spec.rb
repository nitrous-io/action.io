require 'spec_helper'

describe PapertrailController do
  describe "POST webhook" do
    before do
      Settings.should_receive(:papertrail_webhook_key).and_return 'key'
    end

    def do_request(payload, key = 'key', params = {})
      post :webhook, key: key, payload: payload.to_json
    end

    context 'without valid key' do
      it "should respond with forbidden" do
        do_request({}, 'invalid_key')
        expect(controller).to respond_with :forbidden
      end
    end

    context 'with valid key' do
      let!(:payload) { Hash.new }

      it "should submit a delayed job which will parse the papertrail logs" do
        expect {
          do_request payload
        }. to change(Delayed::Job, :count).by(1)

        job = Delayed::Job.last
        expect(job.handler).to match(/'PapertrailEventParser'\nmethod_name: :parse!\nargs:\n- '#{payload.to_json}'/)
      end

      it "should respond with 200 OK" do
        do_request payload
        expect(controller).to respond_with :ok
      end
    end
  end
end
