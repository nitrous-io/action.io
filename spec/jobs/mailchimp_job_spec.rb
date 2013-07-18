require 'spec_helper'

describe MailchimpJob do
  describe '#perform' do
    let!(:email)              { 'test@example.com' }
    let!(:modified_email)     { 'test_modified@example.com' }

    context 'subscribe to list' do
      it "should call Mailchimp wrapper's listSubscribe with the user's email'" do
        Gibbon.should_receive(:listSubscribe).with({ id: Settings.mailchimp_list_id,
                                                     email_address: email,
                                                     merge_vars: { EMAIL: modified_email },
                                                     double_optin: false,
                                                     update_existing: true
                                                   })
        MailchimpJob.new('subscribe', email, modified_email).perform
      end
    end

    context 'unsubscribe to list' do
      it "should call Mailchimp wrapper's listUnsubscribe with the user's email'" do
        Gibbon.should_receive(:listUnsubscribe).with({ id: Settings.mailchimp_list_id,
                                                     email_address: email,
                                                     send_goodbye: false
                                                   })
        MailchimpJob.new('unsubscribe', email, nil).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:email)              { 'test@example.com' }
    let!(:modified_email)     { 'test_modified@example.com' }

    it "should submit a delayed job with email & modified email" do
      expect {
        MailchimpJob.submit_job('subscribe', email, modified_email)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /MailchimpJob.*?event: subscribe/m
      expect(job_handler).to match /MailchimpJob.*?email: #{email}/m
      expect(job_handler).to match /MailchimpJob.*?modified_email: #{modified_email}/m
    end
  end
end
