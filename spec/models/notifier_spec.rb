require 'spec_helper'

describe Notifier do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe ".collaboration_invite" do
    let!(:to)   { create :user, email: 'to@mclov.in'                              }
    let!(:from) { create :user, email: 'from@mclov.in', username: 'from-username' }
    let!(:box)  { create :box,  name: 'mclovins-box', owner: from }

    before do
      @email = Notifier.collaboration_invite(from: from.id, to: to.id, box: box.id)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("to@mclov.in")
      @email.should deliver_from("Nitrous.IO Team <hello@nitrous.io>")
      @email.body.should match(/from-username/)
      @email.body.should match(/mclovins-box/)
    end
  end

  describe ".collaboration_notification" do
    let!(:to)   { create :user, email: 'to@mclov.in', username: 'to-username' }
    let!(:author) { create :user, email: 'from@mclov.in', username: 'author-username' }
    let!(:box)  { create :box, name: 'mclovins-box', owner: author }

    before do
      @email = Notifier.collaboration_notification(to.id, author.username, box.name)
    end

    it "should be delivered to the user" do
      @email.should deliver_to("to@mclov.in")
      @email.should deliver_from("Nitrous.IO Team <hello@nitrous.io>")
      @email.should have_subject(/author-username mentioned you in the box \"mclovins-box\"/)
      @email.body.should match(/to-username/)
      @email.body.should match(/author-username/)
      @email.body.should match(/mclovins-box/)
    end
  end
end
