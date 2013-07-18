require 'spec_helper'

describe UserProfile do

  describe 'subscribe/unsubscribe from newsletter' do
    let!(:user_profile) { create :user_profile }

    context 'when user subscribes to the newsletter' do
      before do
        user_profile.update_attribute(:subscribed_to_newsletter, false)
      end

      it 'calls MailChimpJob with subscribe event and user email' do
        MailchimpJob.should_receive(:submit_job).with("subscribe", user_profile.user.email)
        user_profile.update_attribute(:subscribed_to_newsletter, true)
      end
    end

    context 'when user unsubscribe from the newsletter' do
      before do
        user_profile.update_attribute(:subscribed_to_newsletter, true)
      end

      it 'calls MailChimpJob with unsubscribe event and user email' do
        MailchimpJob.should_receive(:submit_job).with("unsubscribe", user_profile.user.email)
        user_profile.update_attribute(:subscribed_to_newsletter, false)
      end
    end

  end
end
