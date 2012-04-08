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

