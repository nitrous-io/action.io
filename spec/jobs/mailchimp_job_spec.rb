require 'spec_helper'

describe MailchimpJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should call Mailchimp wrapper's listSubscribe with the user's email'" do
      Gibbon.should_receive(:listSubscribe).with({ id: Settings.mailchimp_list_id,
                                                   email_address: user.email,
                                                   merge_vars: { EMAIL: user.email },
                                                   double_optin: false,
                                                   update_existing: true
                                                 })
      MailchimpJob.new('subscribe', user.id).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        MailchimpJob.submit_job('subscribe', user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /MailchimpJob.*?event: subscribe/m
      expect(job_handler).to match /MailchimpJob.*?user_id: #{user.id}/m
    end
  end
end
