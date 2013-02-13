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

shared_examples 'an action that requires access token' do
  context 'when token is invalid' do
    before do
      controller.stub(:doorkeeper_token) { double(accessible?: false, resource_owner_id: user.id ) }
      do_request
    end

    it { should respond_with :unauthorized }
  end
end

shared_examples 'an action that requires access token with scope' do |scope|
  context 'when a valid scope is given' do
    before do
      controller.stub(:doorkeeper_token) { double(accessible?: true, resource_owner_id: user.id, scopes:[scope.to_sym]) }
      do_request
    end

    it { should_not respond_with :unauthorized }
  end

  context 'when an invalid scope is given' do
    before do
      controller.stub(:doorkeeper_token) { double(accessible?: true, resource_owner_id: user.id, scopes:[:"not_#{scope}"]) }
      do_request
    end

    it { should respond_with :unauthorized }
  end
end

shared_examples 'an action when backend is not available' do |scope|
  let!(:disable_backend_setting) { ENV['DISABLE_BACKEND'] }
  before { ENV['DISABLE_BACKEND'] = 'true' }
  after { ENV['DISABLE_BACKEND'] = disable_backend_setting }

  context 'user is not an admin' do
    before { do_request }

    it { should respond_with :unprocessable_entity }
    its('response.body') { should match(/Backend is currently under maintenance./) }
  end

  context 'user is an admin' do
    before { 
      user.update_attribute :admin, true
      Box.any_instance.stub(:push_box_updated_message) { nil }

      do_request
    }

    it { should_not respond_with :unprocessable_entity }
  end
end



