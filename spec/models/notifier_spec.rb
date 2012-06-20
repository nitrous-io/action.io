require 'spec_helper'

describe Notifier do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  context ".invite_confirmation" do
    before do
      @email = Notifier.invite_confirmation('i@mclov.in')
    end

    it "should be delivered to the user" do
      @email.should deliver_to("i@mclov.in")
    end
  end

end