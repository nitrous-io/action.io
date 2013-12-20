require 'spec_helper'

describe MixpanelWebhookHandler do
  let!(:user) { create :unconfirmed_user }
  let!(:users) do
"""
[
  {
    \"$distinct_id\":\"13b20239a29335]\",
    \"$properties\":{
      \"$region\":\"California\",
      \"$email\":\"#{user.email}\",
      \"$last_name\":\"Bovik\",
      \"$created\":\"2012-11-20T15:26:16\",
      \"$country_code\":\"US\",
      \"$first_name\":\"Harry\",
      \"Referring Domain\":\"news.ycombinator.com\",
      \"$city\":\"Los Angeles\",
      \"Last Seen\":\"2012-11-20T15:26:17\",
      \"Referring URL\":\"http://news.ycombinator.com/\",
      \"$last_seen\":\"2012-11-20T15:26:19\"
    }
  }
]
"""
  end

  describe ".handle!" do
    context 'when webhook is triggered after 1 day' do
      it 'sends the 1st confirmation reminder' do
        expect(UserMailer).to receive(:confirmation_reminder_1).with(user.id) { double.as_null_object }
        MixpanelWebhookHandler.handle! users, '1day'
      end
    end

    context 'when webhook is triggered after 7 days' do
      it 'sends the 2nd confirmation reminder' do
        expect(UserMailer).to receive(:confirmation_reminder_2).with(user.id) { double.as_null_object }
        MixpanelWebhookHandler.handle! users, '7days'
      end
    end

    context 'when webhook is triggered after 14 days' do
      it 'sends the 3rd confirmation reminder' do
        expect(UserMailer).to receive(:confirmation_reminder_3).with(user.id) { double.as_null_object }
        MixpanelWebhookHandler.handle! users, '14days'
      end
    end
  end
end
