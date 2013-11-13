require 'spec_helper'

describe GitHub do
  let!(:user) { create :user }

  describe '#initialize' do
    it 'sets the user' do
      github = GitHub.new(user)

      github.user.should == user
    end

    it 'sets a default value of nil for user' do
      github = GitHub.new

      github.user.should == nil
    end
  end

  describe '#client' do
    it 'returns nil if user is not present' do
      github = GitHub.new

      github.client.should be_nil
    end

    it 'returns nil if user does not have an access_token' do
      user.stub(:token_for).with(:github) { nil }
      github = GitHub.new(user)

      github.client.should be_nil
    end

    it 'creates a new Octokit::Client with the user access_token' do
      user.stub(:token_for).with(:github) { 'wtf' }
      allow(Octokit::Client).to receive(:new)

      github = GitHub.new(user)
      client = github.client

      expect(Octokit::Client).to have_received(:new).with hash_including(access_token: 'wtf')
    end

    it 'returns a new Octokit::Client' do
      user.stub(:token_for).with(:github) { 'wtf' }
      client = double('Octokit::Client')
      Octokit::Client.stub(:new) { client }
      github = GitHub.new(user)

      github.client.should == client
    end
  end

  describe '#repositories' do
    let(:client) { double('Octokit::Client') }

    it 'returns an empty array if user is not present' do
      github = GitHub.new

      github.repositories.should == []
    end

    it 'returns an empty array if user is present but does not have an access_token' do
      user.stub(:token_for).with(:github) { nil }
      github = GitHub.new(user)

      github.repositories.should == []
    end

    it 'calls repos twice on the client, 1st time for public repos, 2nd time for member repos' do
      github = GitHub.new(user)
      github.stub(:client) { client }
      client.stub(:repos) { [] }

      github.repositories

      expect(client).to have_received(:repos).twice
    end

    it 'returns a concatenated array containing both public and member repos' do
      github = GitHub.new(user)
      github.stub(:client) { client }
      gh_repo1 = double('gh_repo1')
      gh_repo2 = double('gh_repo2')
      gh_member_repo1 = double('gh_member_repo1')
      repo1 = double('repo1')
      repo2 = double('repo2')
      member_repo1 = double('member_repo1')
      client.stub(:repos).with(no_args) { [ gh_repo1, gh_repo2 ] }
      client.stub(:repos).with(nil, hash_including(type: 'member')) { [ gh_member_repo1 ] }
      github.stub(:repository_for).with(gh_repo1) { repo1 }
      github.stub(:repository_for).with(gh_repo2) { repo2 }
      github.stub(:repository_for).with(gh_member_repo1) { member_repo1 }

      repos = github.repositories

      repos.should =~ [repo1, repo2, member_repo1]
    end
  end

  describe '#repository_for' do
    it 'returns a new Repository instance with properties set from the given GitHub repo' do
      github = GitHub.new(user)
      relations = double('repo1_relations')
      relations.stub(:[]).with(:html).and_return(double(href: 'https://html-url'))
      relations.stub(:[]).with(:clone).and_return(double(href: 'https://clone-url'))
      relations.stub(:[]).with(:git).and_return(double(href: 'git://git-url'))
      relations.stub(:[]).with(:ssh).and_return(double(href: 'ssh://ssh-url'))
      github_repo = double('repo1', id: 69, name: 'emma-watson', full_name: 'actioneer/emma-watson', private: false, rels: relations)

      repo = github.repository_for(github_repo)

      repo.should be_an_instance_of Repository
      repo.id.should == 69
      repo.name.should == 'emma-watson'
      repo.full_name.should == 'actioneer/emma-watson'
      repo.private.should == false
      repo.html_url.should == 'https://html-url'
      repo.clone_url.should == 'https://clone-url'
      repo.git_url.should == 'git://git-url'
      repo.ssh_url.should == 'ssh://ssh-url'
    end
  end

end
