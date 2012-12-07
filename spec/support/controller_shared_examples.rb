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

shared_examples 'an action that returns 403 when not signed in as an addon provider' do
  context 'when not signed in as an addon provider' do
    before do
      user.update_attribute(:addon_provider, false)
      sign_in user.reload
      do_request
    end

    it { should respond_with :forbidden }
  end
end

shared_examples 'an action that returns 401 when without an access token' do
  context 'when authenticating with an invalid access token' do
    let(:token) { nil }

    it 'should return 401' do
      do_request(payload)
      expect(response.status).to eq(401)
    end

    it 'should not save the addon' do
      expect {
        do_request(payload)
      }.not_to change { Addon.count }.by(1)
    end
  end
end

shared_examples 'an action that returns 401 with an invalid access token' do
  context 'when authenticating with an invalid access token' do
    let(:token) { stub :accessible? => false }

    before do
      controller.stub(:doorkeeper_token) { token }
    end

    it 'should return 401' do
      do_request(payload)
      expect(response.status).to eq(401)
    end

    it 'should not save the addon' do
      expect {
        do_request(payload)
      }.not_to change { Addon.count }.by(1)
    end
  end
end

shared_examples 'an action that returns 401 with an access token with invalid scope' do
  context 'when authenticating with an invalid access token' do
    let(:token) { stub :accessible? => true, :scopes => [:foo] }

    before do
      controller.stub(:doorkeeper_token) { token }
    end

    it 'should return 401' do
      do_request(payload)
      expect(response.status).to eq(401)
    end

    it 'should not save the addon' do
      expect {
        do_request(payload)
      }.not_to change { Addon.count }.by(1)
    end
  end
end

shared_examples 'an action that returns 403 with an invalid manifest' do
  context 'when authenticating with an invalid manifest' do
    it 'should return 403' do
      do_request(payload)
      expect(response.status).to eq(403)
    end

    it 'should not save the addon' do
      expect {
        do_request(payload)
      }.not_to change { Addon.count }.by(1)
    end
  end
end
