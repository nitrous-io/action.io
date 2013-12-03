require 'spec_helper'

describe GithubUser do
  let!(:user) { create :user }

  describe '#initialize' do
    it 'sets the user' do
      GithubUser.new(user).user.should == user
    end

    it 'sets a default value of nil for user' do
      GithubUser.new.user.should == nil
    end
  end

  describe '#client' do
    it 'returns nil if user is not present' do
      github_user = GithubUser.new

      github_user.client.should be_nil
    end

    it 'returns nil if user does not have a token for GitHub' do
      user.stub(:token_for).with(:github) { nil }
      github_user = GithubUser.new(user)

      github_user.client.should be_nil
    end

    it "creates a new Octokit::Client with the user's GitHub token" do
      user.stub(:token_for).with(:github) { 'wtf' }
      allow(Octokit::Client).to receive(:new)

      github_user = GithubUser.new(user)
      client = github_user.client

      expect(Octokit::Client).to have_received(:new).with hash_including(oauth_token: 'wtf')
    end

    it 'returns a new Octokit::Client' do
      user.stub(:token_for).with(:github) { 'wtf' }
      client = double('Octokit::Client')
      Octokit::Client.stub(:new) { client }
      github_user = GithubUser.new(user)

      github_user.client.should == client
    end
  end

  describe '#authenticated?' do
    let(:user) { create :user }
    let(:github_user) { GithubUser.new(user) }

    context 'when there is no client' do
      before { github_user.stub(:client) { nil } }

      it 'returns false' do
        github_user.authenticated?.should be_false
      end
    end

    context 'when there is a client' do
      let(:client) { double('Octokit::Client') }

      before { github_user.stub(:client) { client } }

      it 'delegates to the client' do
        client.should_receive(:authenticated?) { true }
        github_user.authenticated?.should == true
        client.should_receive(:authenticated?) { false }
        github_user.authenticated?.should == false
      end
    end
  end

  describe '#has_company?' do
    let(:user) { create :user }
    let(:client) { double('Octokit::Client') }

    it 'returns false if user is not present' do
      GithubUser.new.has_company?.should == false
    end

    it "returns false if user is present but there's no client" do
      github_user = GithubUser.new(user)
      github_user.stub(:client) { nil }

      github_user.has_company?.should == false
    end

    context 'when user can be authenticated with GitHub' do
      let(:github_user) { GithubUser.new(user) }
      let(:profile) { double('Octokit::Client#user') }

      before do
        github_user.stub(:client) { client }
        client.stub(:user) { profile }
      end

      context 'and has a company in their profile' do
        before { profile.stub(:company) { 'Nutritious.IO' } }

        it 'returns true' do
          github_user.has_company?.should == true
        end
      end

      context 'and does not have a company in their profile' do
        before { profile.stub(:company) { nil } }

        it 'returns false' do
          github_user.has_company?.should == false
        end
      end
    end
  end

  describe '#profile' do
    let(:user) { create :user }
    let(:client) { double('Octokit::Client') }

    it 'returns nil if user is not present' do
      GithubUser.new.profile.should be_nil
    end

    it "returns false if user is present but there's no client" do
      github_user = GithubUser.new(user)
      github_user.stub(:client) { nil }

      github_user.profile.should be_nil
    end

    it 'returns the user from Octokit::Client' do
      github_user = GithubUser.new(user)
      github_user.stub(:client) { client }
      profile = double
      client.should_receive(:user) { profile }

      github_user.profile.should == profile
    end
  end

  describe '#add_key' do
    it 'delegates to the client' do
      github_user = GithubUser.new(user)
      client = double('Octokit::Client').as_null_object
      github_user.stub(:client) { client }

      github_user.add_key('emma-watsons-box', 'ima-ssh-key-ask-me-anything')

      expect(client).to have_received(:add_key).with('emma-watsons-box', 'ima-ssh-key-ask-me-anything')
    end
  end

end
