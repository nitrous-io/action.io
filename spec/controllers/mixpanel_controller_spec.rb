require 'spec_helper'

describe MixpanelController do
  describe "POST confirmation" do
    def do_request(users, event = 'event', params = {})
      post :confirmation, event: event, users: users.to_json
    end

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
