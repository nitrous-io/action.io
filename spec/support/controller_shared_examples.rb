shared_examples 'an action that requires sign in' do
  context 'when not signed in' do
    before do
      sign_out :user
      do_request
    end

    it 'redirects to sign in page' do
      response.should redirect_to new_user_session_url
    end
  end
end

shared_examples 'an action that returns 401 when not signed in' do
  context 'when not signed in' do
    before do
      sign_out :user
      do_request
    end

    it { should respond_with :unauthorized }
  end
end

shared_examples 'an action that returns 403 when not signed in as an admin' do
  context 'when not signed in as an admin' do
    before do
      user.update_attribute(:admin, false)
      sign_in user.reload
      do_request
    end

    it { should respond_with :forbidden }
  end
end

