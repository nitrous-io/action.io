require 'spec_helper'

shared_examples_for "a class which deals with subscribing/unsubscribing from a Mailchimp list" do |attribute, list_id|
  describe "subscribe/unsubscribe from #{attribute}" do
    context "when user subscribes to #{attribute}" do
      let!(:user_profile) { create :user_profile, attribute.to_s => false }

      it 'calls MailChimpJob with subscribe event and user email' do
        MailchimpJob.should_receive(:submit_job).with("subscribe", list_id, user_id: user_profile.user.id)
        user_profile.update_attribute(attribute, true)
      end
    end

    context "when user unsubscribes from #{attribute}" do
      let!(:user_profile) { create :user_profile }

      it 'calls MailChimpJob with unsubscribe event and user email' do
        MailchimpJob.should_receive(:submit_job).with("unsubscribe", list_id, user_id: user_profile.user.id)
        user_profile.update_attribute(attribute, false)
      end
    end
  end
end

describe UserProfile do
  it_behaves_like "a class which deals with subscribing/unsubscribing from a Mailchimp list", :subscribed_to_monthly_newsletter,
                                                                                              Settings.mailchimp_monthly_newsletter_list_id

  it_behaves_like "a class which deals with subscribing/unsubscribing from a Mailchimp list", :subscribed_to_product_announcements,
                                                                                              Settings.mailchimp_product_announcements_list_id
end
