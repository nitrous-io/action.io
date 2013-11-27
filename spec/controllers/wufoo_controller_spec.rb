require 'spec_helper'

describe WufooController do
  describe 'POST webhook' do
    let!(:user) { create :user, username: 'emma', email: 'hermione@hogwarts.edu' }

    before :each do
      Settings.should_receive(:wufoo_webhook_key).and_return 'wufoo-key'
    end

    def do_request(form_id: nil, username: nil, email: nil, key: 'wufoo-key')
      post :webhook, HandshakeKey: key, form_id: form_id, Field9: username, Field11: email
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
          user.should_not_receive(:find_by_username)
          do_request form_id: 'unknown-form-id', username: 'emma'
          expect(controller).to respond_with :ok
        end
      end

      context 'and with the business survey form ID' do
        it 'looks up the user by username' do
          User.should_receive(:find_by_username).with('emma') { user }
          user.stub(:fill_n2o_for_business_survey!)
          do_request form_id: 'nitrous-for-business', username: 'emma'
          expect(controller).to respond_with :ok
        end

        it 'falls back to looking up the user by email if she cannot be found by username' do
          User.stub(:find_by_username).with('granger') { nil }
          User.should_receive(:find_by_email).with('hermione@hogwarts.edu') { user }
          user.stub(:fill_n2o_for_business_survey!)
          do_request form_id: 'nitrous-for-business', username: 'granger', email: 'hermione@hogwarts.edu'
          expect(controller).to respond_with :ok
        end

        context 'and a user can be found' do
          before { User.should_receive(:find_by_username).with('emma') { user } }

          it 'should give N2O bonus to her' do
            User.stub(:find_by_username).with('emma') { user }
            user.should_receive(:fill_n2o_for_business_survey!)
            do_request form_id: 'nitrous-for-business', username: 'emma'
            expect(controller).to respond_with :ok
          end
        end
      end
    end

  end
end
