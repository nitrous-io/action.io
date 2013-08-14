require 'spec_helper'

describe MailchimpJob do
  let!(:user)     { create :user, email: 'test@nitrous.io' }
  let!(:list_id)  { 'abcdef' }

  describe '#perform' do
    context 'subscribe to list' do
      context 'with user_id' do
        context 'full name is not present' do
          before { user.update_attribute :full_name, nil }

          it "should call Mailchimp wrapper's listSubscribe with the user's email and fullname'" do
            Gibbon.should_receive(:listSubscribe).with({ id: list_id,
                                                         email_address: user.email,
                                                         merge_vars: {
                                                           EMAIL: user.unconfirmed_email,
                                                           FNAME: user.username
                                                         },
                                                         double_optin: false,
                                                         update_existing: true
                                                       })

            MailchimpJob.new('subscribe', list_id, user_id: user.id).perform
          end
        end

        context 'full name is present' do
          it "should call Mailchimp wrapper's listSubscribe with the user's email and fullname'" do
            Gibbon.should_receive(:listSubscribe).with({ id: list_id,
                                                         email_address: user.email,
                                                         merge_vars: {
                                                           EMAIL: user.unconfirmed_email,
                                                           FNAME: user.full_name
                                                         },
                                                         double_optin: false,
                                                         update_existing: true
                                                       })

            MailchimpJob.new('subscribe', list_id, user_id: user.id).perform
          end
        end
      end

      context "with email" do
        it "should call Mailchimp wrapper's listSubscribe with the user's email and fullname'" do
          Gibbon.should_receive(:listSubscribe).with({ id: list_id,
                                                       email_address: 'i@mclov.in',
                                                       merge_vars: {
                                                         EMAIL: nil,
                                                         FNAME: nil
                                                       },
                                                       double_optin: false,
                                                       update_existing: true
                                                     })

          MailchimpJob.new('subscribe', list_id, email: 'i@mclov.in').perform
        end
      end
    end

    context 'unsubscribe to list' do
      context 'with user_id' do
        it "should call Mailchimp wrapper's listUnsubscribe with the user's email'" do
          Gibbon.should_receive(:listUnsubscribe).with({
                                                         id: list_id,
                                                         email_address: user.email,
                                                         send_goodbye: false
                                                       })
          MailchimpJob.new('unsubscribe', list_id, user_id: user.id).perform
        end
      end

      context 'with email' do
        it "should call Mailchimp wrapper's listUnsubscribe with the user's email'" do
          Gibbon.should_receive(:listUnsubscribe).with({
                                                         id: list_id,
                                                         email_address: 'i@mclov.in',
                                                         send_goodbye: false
                                                       })
          MailchimpJob.new('unsubscribe', list_id, email: 'i@mclov.in').perform
        end
      end
    end
  end

  describe ".submit_job" do
    it "should submit a delayed job with email & modified email" do
      expect {
        MailchimpJob.submit_job('subscribe', list_id, user_id: user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/MailchimpJob.*?event: subscribe/m)
      expect(job_handler).to match(/MailchimpJob.*?user_id: #{user.id}/m)
      expect(job_handler).to match(/MailchimpJob.*?list_id: #{list_id}/m)
    end
  end
end
