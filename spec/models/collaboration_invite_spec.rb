require 'spec_helper'

describe CollaborationInvite do
  describe "Validations" do
    subject { create :collaboration_invite }
    it { should validate_presence_of :email }
    it { should validate_uniqueness_of(:email).scoped_to(:box_id) }

    it { should_not allow_value("pete@nitrous.io, aj@nitrous.io, arun@nitrous.io").for(:email) }
    it { should_not allow_value(" pete@nitrous.io aj@nitrous.io ").for(:email) }
    it { should_not allow_value("a run@nitrous.io").for(:email) }

    it "should clean up the email string before entry" do
      @collaboration_invite = create :collaboration_invite, email: "  spaced@email.com  "
      @collaboration_invite.email.should == "spaced@email.com"

      @collaboration_invite = build :invite, email: "i+x@mclov.in"
      @collaboration_invite.should be_valid

      @collaboration_invite = create :collaboration_invite, email: "I@MCloV.IN"
      @collaboration_invite.email.should == "i@mclov.in"
    end
  end

  describe "Callbacks" do
    describe "after_create" do
      it 'should send an email to the recipient of the invite' do
        expect {
          @collaboration_invite = create :collaboration_invite
        }.to change(Delayed::Job, :count).by(1)
        InviteMailer.should_receive(:send_collaboration_invite).with(@collaboration_invite.id) { double.as_null_object }
        Delayed::Job.last.invoke_job
      end
    end
  end

  describe "Associations" do
    it { should belong_to :box }
  end

  describe "Scopes" do
    before do
      @invite_1 = create :collaboration_invite
      @invite_2 = create :collaboration_invite
      @invite_3 = nil
      @invite_4 = nil
      @invite_5 = create :collaboration_invite, state: 'accepted'
      @invite_6 = create :collaboration_invite, state: 'accepted'
      @invite_7 = nil
      @invite_8 = nil

      Timecop.travel(30.days.ago) { @invite_8 = create :collaboration_invite }
      Timecop.travel(25.days.ago) { @invite_7 = create :collaboration_invite }
      Timecop.travel(15.days.ago) { @invite_3 = create :collaboration_invite }
      Timecop.travel(5.days.ago)  { @invite_4 = create :collaboration_invite }
      # A reminder was sent to one of the activated invites
      Timecop.travel(13.days.ago) do
        @invite_8.update_attribute :last_reminded_at, Time.now
      end
    end

    context "activated" do
      it "should return invites which are activated" do
        CollaborationInvite.activated.to_a.should =~ [@invite_1, @invite_2, @invite_3, @invite_4, @invite_7, @invite_8]
      end
    end

    context "accepted" do
      it "should return invites which are accepted" do
        CollaborationInvite.accepted.to_a.should =~ [@invite_5, @invite_6]
      end
    end

    context "needs_reminder" do
      it "should return invites which are in an activated state and have been created more than two weeks ago" do
        CollaborationInvite.needs_reminder.to_a.should =~ [@invite_3, @invite_7]
      end
    end
  end

  describe "state machine" do
    describe "#accept" do
      let!(:invite) { create :collaboration_invite, email: 'i@mclov.in' }

      before do
        Timecop.freeze
        @now = Time.now
      end

      after do
        Timecop.return
      end

      it "should update the accepted_at field with the current time" do
        invite.accept!
        invite.reload.accepted_at.to_i.should == @now.to_i
      end

      context 'when invite is linked to a box' do
        let(:user)  { create :user }
        let(:box)   { create :box }

        it 'makes the user with the same email the box collaborators' do
          invite = create :collaboration_invite, email: user.email, box_id: box.id
          invite.accept!
          box.reload.collaborators.should include(user)
        end
      end
    end
  end

end
