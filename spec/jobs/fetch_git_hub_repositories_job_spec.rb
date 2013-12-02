require 'spec_helper'

describe FetchGitHubRepositoriesJob do
  describe '#perform' do
    let!(:user) { create :user, id: 69 }
    let(:github) { double.as_null_object }
    let(:channel) { double.as_null_object }

    context 'when user has GitHub repositories' do
      let!(:stub_repositories) { [ { name: 'dev-cookbook' }, { name: 'action-io' } ] }

      before do
        User.stub(:find).with(69) { user }
        GitHub.stub(:new).with(user) { github }
        github.stub(:repositories).and_return stub_repositories
      end

      it "sends a message via Pusher with user's repositories to the user's channel" do
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, data|
          message.should == 'aio:fetch_repos'
          data.should == {
            status: 'ok',
            repositories: stub_repositories
          }.to_json
        end

        FetchGitHubRepositoriesJob.new(69).perform
      end
    end

    context 'when the GitHub API request raises an Octokit::Error' do
      before do
        User.stub(:find).with(69) { user }
        GitHub.stub(:new).with(user) { github }
        github.stub(:repositories).and_raise Octokit::Error.new
      end

      it 'sends a message via Pusher with the error' do
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, data|
          message.should == 'aio:fetch_repos'
          data.should == {
            status: 'fail',
            error: 'Octokit::Error'
          }.to_json
        end

        FetchGitHubRepositoriesJob.new(69).perform
      end
    end
  end
end
