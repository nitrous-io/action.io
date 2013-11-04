require 'spec_helper'

describe GithubUser do
  describe ".init" do
    let(:user) { create :user }

    context 'when the user has already authenticate with github' do
      let(:token) { "github_token" }

      before do
        @authentication = create :authentication, provider: 'github', token: token, user: user
      end

      it 'returns a client that can authenticate with github' do
        client = double
        Octokit::Client.should_receive(:new).with(hash_including(oauth_token: token)) { client }
        GithubUser.init(user).should eq(client)
      end
    end

    context 'when ther user did not authenticate with github' do
      it 'returns NON_AUTHENTICATED_USER' do
        Octokit::Client.should_not_receive(:new)
        GithubUser.init(user).should eq(GithubUser::NON_AUTHENTICATED_USER)
      end
    end
  end
end
