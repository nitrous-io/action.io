require 'spec_helper'

describe LinkedinUser do
  describe ".init" do
    let(:user) { create :user }

    context 'when the user has already authenticated with linkedin' do
      before do
        @authentication = create :authentication, provider: 'linkedin', user: user
      end

      it 'returns a LinkedIn User object' do
        client = double
        lnkd_user = double

        LinkedIn::Client.should_receive(:new).with(Settings.linkedin_id, Settings.linkedin_secret) { client }
        client.should_receive(:authorize_from_access).with(@authentication.token, @authentication.secret)
        client.should_receive(:profile).with(fields: %w(positions)) { lnkd_user }

        LinkedinUser.init(user).should eq(lnkd_user)
      end
    end

    context 'when ther user has not authenticate with linkedin' do
      it 'returns NON_AUTHENTICATED_USER' do
        LinkedIn::Client.should_not_receive(:new)
        LinkedinUser.init(user).should eq(LinkedinUser::NON_AUTHENTICATED_USER)
      end
    end

  end
end
