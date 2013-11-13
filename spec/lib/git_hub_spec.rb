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
      client.stub(:repos).with(no_args) { ['dotfiles', 'emma-watson'] }
      client.stub(:repos).with(nil, hash_including(type: 'member')) { ['dev-cookbook'] }

      repos = github.repositories

      repos.should =~ ['dotfiles', 'emma-watson', 'dev-cookbook']
    end
  end

end
