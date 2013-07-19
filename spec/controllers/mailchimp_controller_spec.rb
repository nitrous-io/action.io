require 'spec_helper'

describe MailchimpController do
  describe 'POST webhook' do
    let!(:user) { create :user }

    before :each do
      Settings.should_receive(:mailchimp_webhook_key).and_return 'key'
    end

    def do_request(type, email, key = 'key', params = {})
      put :webhook, key: key, type: type, data: params.merge!(email: email)
    end

    context 'without valid key' do
      it "should respond with forbidden" do
        do_request 'unsubscribe', user.email, 'invalid_key'
        expect(controller).to respond_with :forbidden
      end
    end

    context 'with valid key' do
      context 'Received unsubscribed message from Mailchimp' do
        context 'doesnt find a user for the given email' do
          it 'should do nothing' do
            User.any_instance.should_not_receive :update_attribute
            do_request 'unsubscribe', 'some@example.com'

            expect(controller).to respond_with :ok
          end
        end

        context 'when user is unsubscribed from the monthly newsletters' do
          context 'finds a user with the given email' do
            it 'should set subscribed_to_monthly_newsletter in user profile to false' do
              do_request 'unsubscribe', user.email, 'key', list_id: Settings.mailchimp_monthly_newsletter_list_id
              expect(user.user_profile.subscribed_to_monthly_newsletter).to be_false
              expect(controller).to respond_with :ok
            end

            it 'should set subscribed_to_product_announcements in user profile to false' do
              do_request 'unsubscribe', user.email, 'key', list_id: Settings.mailchimp_product_announcements_list_id
              expect(user.user_profile.subscribed_to_product_announcements).to be_false
              expect(controller).to respond_with :ok
            end
          end
        end
      end
    end
  end

end
