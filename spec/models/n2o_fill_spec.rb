require 'spec_helper'

describe N2oFill do
  it { should belong_to :user }

  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :amount }
  it { should_not allow_mass_assignment_of :kind }
  it { should_not allow_mass_assignment_of :description }

  describe "callbacks" do
    context "when it's of the INVITING_USER_BONUS kind" do
      let!(:user) { create :user }

      it "should send an email to the user notifying that he has received N2O" do
        n2o_fill = create :n2o_fill, kind: N2oFill::Kind::INVITING_USER_BONUS, description: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, amount: 0

        UserMailer.should_receive(:n2o_bonus_alert).with(n2o_fill.id) { stub.as_null_object }
        Delayed::Job.last.invoke_job
      end
    end
  end
end
