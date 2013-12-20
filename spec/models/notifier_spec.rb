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
      expect(@email).to deliver_to("to@mclov.in")
      expect(@email).to deliver_from("Nitrous.IO Team <hello@nitrous.io>")
      expect(@email.body).to match(/from-username/)
      expect(@email.body).to match(/mclovins-box/)
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
      expect(@email).to deliver_to("to@mclov.in")
      expect(@email).to deliver_from("Nitrous.IO Team <hello@nitrous.io>")
      expect(@email).to have_subject(/author-username mentioned you in the box \"mclovins-box\"/)
      expect(@email.body).to match(/to-username/)
      expect(@email.body).to match(/author-username/)
      expect(@email.body).to match(/mclovins-box/)
    end
  end
end
