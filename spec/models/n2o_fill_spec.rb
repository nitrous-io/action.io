require 'spec_helper'

describe N2oFill do
  it { should belong_to :user }
  it { should belong_to :resource }

  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :amount }
  it { should_not allow_mass_assignment_of :kind }
  it { should_not allow_mass_assignment_of :description }
  it { should_not allow_mass_assignment_of :resource_id }
  it { should_not allow_mass_assignment_of :resource_type }

  describe "callbacks" do
    context "when it's of the INVITING_USER_BONUS kind" do
      let!(:user) { create :user }

      it "should send an email to the user notifying that he has received N2O" do
        n2o_fill = create :n2o_fill, kind: N2oFill::Kind::INVITING_USER_BONUS, description: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, amount: 0

        UserMailer.should_receive(:n2o_bonus_alert).with(n2o_fill.id) { double.as_null_object }
        Delayed::Job.last.invoke_job
      end
    end
  end

  describe "#invitee_email" do
    let!(:n2o_fill) { create :n2o_fill }

    context "when it is associated with an invite" do
      let!(:invite) { create :invite }

      before do
        n2o_fill.resource = invite
        n2o_fill.save
      end

      it "should return the email of the invite" do
        expect(n2o_fill.invitee_email).to eq invite.email
      end
    end

    context "when it is not associated with an invite" do
      it "should return nil" do
        expect(n2o_fill.invitee_email).to be_nil
      end
    end
  end
end
