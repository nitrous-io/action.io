require 'spec_helper'

describe 'tty keys cookie' do
  let!(:user) { create :user }

  context 'when signed in' do
    before do
      post user_session_path, 'user[username]' => user.username, 'user[password]' => user.password
      set_cookie '_aio_tty_keys', 'some tty keys'
    end

    context 'upon sign out' do
      it 'gets removed' do
        delete destroy_user_session_path
        cookies['_aio_tty_keys'].should be_blank
      end
    end

    context 'when session expires' do
      it 'gets removed' do
        set_cookie '_aio_session', ''
        get root_path
        cookies['_aio_tty_keys'].should be_blank
      end
    end

    context 'when not signing out' do
      it 'does not get removed' do
        get root_path
        cookies['_aio_tty_keys'].should be_present
      end
    end
  end
end
