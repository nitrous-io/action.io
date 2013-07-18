require 'spec_helper'

describe MailchimpController do
  describe 'POST webhook' do
    let!(:user) { create :user }

    before :each do
      Settings.should_receive(:mailchimp_webhook_key).and_return 'key'
    end

    def do_request(type, email)
      put :webhook, type: type, data: { email: email }
    end

    context 'Received unsubscribed message from Mailchimp' do
      context 'finds a user with the given email' do
        it 'should set subscribed_to_newsletter in user profile to false' do
          do_request 'unsubscribe', user.email
          expect(user.user_profile.subscribed_to_newsletter).to be_false

          expect(controller).to respond_with :no_content
        end
      end

      context 'doesnt find a user for the given email' do
        it 'should do nothing' do
          User.any_instance.should_not_receive :update_attribute
          do_request 'unsubscribe', 'some@example.com'

          expect(controller).to respond_with :no_content
        end
      end
    end
  end

end
