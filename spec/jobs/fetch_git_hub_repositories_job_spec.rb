require 'spec_helper'

describe FetchGitHubRepositoriesJob do
  describe '#perform' do
    let!(:user) { create :user, id: 69 }
    let(:channel) { double.as_null_object }
    let!(:stub_repositories) { [ { name: 'dev-cookbook' }, { name: 'action-io' } ] }

    before do
      User.stub(:find).with(69) { user }
    end

    it "gets the user's repositories" do
      Pusher.stub(:[]) { channel }
      channel.stub(:trigger)
      expect(user).to receive(:repositories)

      FetchGitHubRepositoriesJob.new(user.id).perform
    end

    it "sends a message via Pusher with user's repositories to the user's channel" do
      user.stub(:repositories).and_return stub_repositories
      expect(Pusher).to receive(:[]).with('private-user-69') { channel }
      expect(channel).to receive(:trigger) do |message, repositories|
        message.should == 'aio:fetch_repos'
        repositories.should == stub_repositories.to_json
      end

      FetchGitHubRepositoriesJob.new(69).perform
    end
  end
end
