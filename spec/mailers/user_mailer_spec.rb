require 'spec_helper'

describe UserMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "n2o_bonus_alert" do
    let!(:user)     { create :user, email: 'naive@user.io' }
    let!(:n2o_fill) { create :n2o_fill, kind: N2oFill::Kind::INVITING_USER_BONUS, description: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, amount: 10, user: user }

    it "sends an email to the user who's account received N2O fills" do
      mail = UserMailer.n2o_bonus_alert n2o_fill.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/10 units of N2O/)
    end
  end

  describe "private_beta_thanks" do
    let!(:user)     { create :user, email: 'naive@user.io' }

    it "sends a thank you note to a user" do
      mail = UserMailer.private_beta_thanks user.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/is now open to all/)
    end
  end

  describe "box_memory_limit_hit_alert" do
    let!(:user)     { create :user, email: 'naive@user.io' }
    let!(:box)      { create :box, owner: user }

    it "sends an alert notifying the user that the box has hit its memory limits" do
      mail = UserMailer.box_memory_hit_limit_alert box.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match"You seem to have hit memory limits on your Nitrous.IO box - #{box.name}"
      expect(mail.body).to match(/upgrade the memory/)
    end
  end
end
