require 'spec_helper'

describe WufooController do
  describe 'POST webhook' do
    let!(:user) { create :user, username: 'emma', email: 'hermione@hogwarts.edu' }

    before :each do
      expect(Settings).to receive(:wufoo_webhook_key).and_return 'wufoo-key'
    end

    def do_request(form_id: nil, username: nil, email: nil, key: 'wufoo-key')
      post :webhook, HandshakeKey: key, form_id: form_id
    end

    context 'without valid key' do
      it 'should respond with forbidden' do
        do_request form_id: 'nitrous-for-business', username: 'emma', key: 'invalid_key'
        expect(controller).to respond_with :forbidden
      end
    end

    context 'with valid key' do
      context 'and with an unrecognized form ID' do
        it 'does nothing' do
          expect(user).not_to receive(:find_by_username)
          do_request form_id: 'unknown-form-id', username: 'emma'
          expect(controller).to respond_with :ok
        end
      end

      context 'and with the business survey form ID' do
        def do_request(form_id: nil, username: nil, email: nil, key: 'wufoo-key')
          post :webhook, HandshakeKey: key, form_id: 'nitrous-for-business', Field9: username, Field11: email
        end

        it 'looks up the user by username' do
          expect(User).to receive(:find_by_username).with('emma') { user }
          user.stub(:fill_n2o_for_business_survey!)
          do_request username: 'emma'
          expect(controller).to respond_with :ok
        end

        it 'falls back to looking up the user by email if she cannot be found by username' do
          User.stub(:find_by_username).with('granger') { nil }
          expect(User).to receive(:find_by_email).with('hermione@hogwarts.edu') { user }
          user.stub(:fill_n2o_for_business_survey!)
          do_request username: 'granger', email: 'hermione@hogwarts.edu'
          expect(controller).to respond_with :ok
        end

        context 'and a user can be found' do
          before { User.stub(:find_by_username).with('emma') { user } }

          it 'should reward her with an N2O bonus' do
            expect(user).to receive(:fill_n2o_for_business_survey!)
            do_request username: 'emma'
            expect(controller).to respond_with :ok
          end
        end
      end

      context 'and with user survey #1 form ID' do
        def do_request(form_id: nil, username: nil, email: nil, key: 'wufoo-key')
          post :webhook, HandshakeKey: key, form_id: 'nitrousio-new-user-survey', Field227: username, Field226: email
        end

        it 'looks up the user by username' do
          expect(User).to receive(:find_by_username).with('emma')
          do_request username: 'emma'
          expect(controller).to respond_with :ok
        end

        it 'falls back to looking up the user by email if she cannot be found by username' do
          User.stub(:find_by_username).with('granger') { nil }
          expect(User).to receive(:find_by_email).with('hermione@hogwarts.edu') { user }
          expect(user).to receive(:fill_n2o_for_user_survey_1!)
          do_request username: 'granger', email: 'hermione@hogwarts.edu'
          expect(controller).to respond_with :ok
        end

        context 'and a user can be found' do
          before { User.stub(:find_by_username).with('emma') { user } }

          it 'should reward her with an N2O bonus' do
            expect(user).to receive(:fill_n2o_for_user_survey_1!)
            do_request username: 'emma'
            expect(controller).to respond_with :ok
          end
        end
      end
    end

  end
end
